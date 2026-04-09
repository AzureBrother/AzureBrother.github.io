# Azure Automation: 180-Day Guest Inactivity Report

This guide explains how to set up an Azure Automation Account to automatically identify Guest users who have not logged in for over 180 days, and send a summary report via a Shared Mailbox.

This solution operates entirely headlessly using a **System-Assigned Managed Identity** and the **Microsoft Graph API**.

## Prerequisites
* An active Azure Subscription.
* Global Administrator or Privileged Role Administrator rights (to assign Graph API permissions).
* A Shared Mailbox in Exchange Online.
* The Object ID of an Entra ID Group (if you want to filter out specific guests).

---

## Step 1: Create the Azure Automation Account
1. Log into the [Azure Portal](https://portal.azure.com) and search for **Automation Accounts**.
2. Click **Create**, fill in your resource group and naming details, and deploy the resource.

## Step 2: Enable the Managed Identity
1. Navigate to your new Automation Account.
2. On the left menu, under **Account Settings**, select **Identity**.
3. Under the **System assigned** tab, set the Status to **On** and click **Save**.
4. Note the **Object (principal) ID** that is generated.

## Step 3: Grant Graph API Permissions
Because you cannot assign Microsoft Graph *Application* permissions to a Managed Identity via the Azure Portal GUI, you must use PowerShell.

Open an administrative PowerShell console, ensure the `Microsoft.Graph` module is installed, and run the following script. **Be sure to replace `$AppName` with the exact name of your Automation Account.**

```powershell
Connect-MgGraph -Scopes "AppRoleAssignment.ReadWrite.All", "Application.Read.All"

$AppName = "Your-Automation-Account-Name"
$ManagedIdentity = Get-MgServicePrincipal -Filter "displayName eq '$AppName'"
$GraphApp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"

# Required Graph API Permissions
$Roles = @(
    "User.Read.All", 
    "AuditLog.Read.All", 
    "Directory.Read.All", 
    "GroupMember.Read.All", 
    "Mail.Send"
)

foreach ($Role in $Roles) {
    $AppRole = $GraphApp.AppRoles | Where-Object { $_.Value -eq $Role }
    New-MgServicePrincipalAppRoleAssignment -PrincipalId $ManagedIdentity.Id -ServicePrincipalId $ManagedIdentity.Id -ResourceId $GraphApp.Id -AppRoleId $AppRole.Id
    Write-Host "Assigned $Role to $AppName"
}
```

## Step 4: Create the Runbook
In your Automation Account, go to `Process Automation > Runbooks`.

Click `Create a runbook`.

Name it (e.g., Get-StaleGuestAccounts), set the **Runbook** type to `PowerShell`, and set the **Runtime version** to `5.1` (or 7.2).

Paste the final script into the editor. (Remember to update the configuration variables at the top of the script with your specific Group ID and email addresses).

```powershell
# 1. Configuration Variables
$TargetGroupId = "YOUR_GROUP_OBJECT_ID_HERE"
$GroupName = "Guest_Accounts" # Ensure this matches your actual group name
$SharedMailboxAddress = "YOUR_SHARED_MAILBOX@yourdomain.com"
$RecipientAddress = "recipient@yourdomain.com"
$180DaysAgo = (Get-Date).AddDays(-180)

# 2. Authenticate and get a Microsoft Graph Access Token
try {
    Write-Output "Authenticating with Managed Identity..."
    Connect-AzAccount -Identity | Out-Null
    $AccessToken = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com").Token
}
catch {
    Write-Error "Failed to authenticate. Ensure System-Assigned Managed Identity is enabled."
    exit
}

$Headers = @{
    "Authorization" = "Bearer $AccessToken"
    "Content-Type"  = "application/json"
}
$GraphApiVersion = "v1.0"

# 3. Fetch members of the target group (Paginated)
Write-Output "Fetching members of target group..."
$GroupMemberIds = @()
$GroupMembersUrl = "https://graph.microsoft.com/$GraphApiVersion/groups/$TargetGroupId/members?`$select=id"

do {
    $GroupMembersResponse = Invoke-RestMethod -Method Get -Uri $GroupMembersUrl -Headers $Headers
    if ($GroupMembersResponse.value) {
        $GroupMemberIds += $GroupMembersResponse.value.id
    }
    $GroupMembersUrl = $GroupMembersResponse.'@odata.nextLink'
} while ($null -ne $GroupMembersUrl)

# 4. Query Microsoft Graph for Guest Users (Paginated)
Write-Output "Fetching Guest accounts..."
$Guests = @()
$GuestsUrl = "https://graph.microsoft.com/$GraphApiVersion/users?`$filter=userType eq 'Guest'&`$select=id,displayName,mail,userPrincipalName,createdDateTime,accountEnabled,signInActivity"

do {
    $GuestsResponse = Invoke-RestMethod -Method Get -Uri $GuestsUrl -Headers $Headers
    if ($GuestsResponse.value) {
        $Guests += $GuestsResponse.value
    }
    $GuestsUrl = $GuestsResponse.'@odata.nextLink'
} while ($null -ne $GuestsUrl)

# 5. Process and Format the Data
Write-Output "Processing $($Guests.Count) guest data records..."
[array]$ProcessedGuests = foreach ($Guest in $Guests) {
    
    $LastInteractive = $null
    $LastNonInteractive = $null
    $AbsoluteLastLogin = $null

    if ($null -ne $Guest.signInActivity) {
        if ($null -ne $Guest.signInActivity.lastSignInDateTime) { 
            $LastInteractive = [datetime]$Guest.signInActivity.lastSignInDateTime 
        }
        if ($null -ne $Guest.signInActivity.lastNonInteractiveSignInDateTime) { 
            $LastNonInteractive = [datetime]$Guest.signInActivity.lastNonInteractiveSignInDateTime 
        }
    }

    if ($LastInteractive -and $LastNonInteractive) {
        $AbsoluteLastLogin = if ($LastInteractive -gt $LastNonInteractive) { $LastInteractive } else { $LastNonInteractive }
    } elseif ($LastInteractive) { 
        $AbsoluteLastLogin = $LastInteractive 
    } elseif ($LastNonInteractive) { 
        $AbsoluteLastLogin = $LastNonInteractive 
    }

    # Evaluate our two specific conditions
    $IsStale = if (($null -eq $AbsoluteLastLogin) -or ($AbsoluteLastLogin -lt $180DaysAgo)) { "Yes" } else { "No" }
    $InGroup = if ($GroupMemberIds -contains $Guest.id) { "Yes" } else { "No" }

    [PSCustomObject]@{
        DisplayName = $Guest.displayName
        Mail = if ([string]::IsNullOrWhiteSpace($Guest.mail)) { "N/A" } else { $Guest.mail }
        UserPrincipalName = $Guest.userPrincipalName
        Id = $Guest.id
        AccountEnabled = $Guest.accountEnabled
        CreatedDateTime = $Guest.createdDateTime
        LastLogin = if ($AbsoluteLastLogin) { $AbsoluteLastLogin.ToString("yyyy-MM-dd HH:mm:ss") } else { "Never" }
        "In_Target_Group" = $InGroup
        "Inactive_180_Days" = $IsStale
        SortDate = $AbsoluteLastLogin 
    }
}

# Sort descending by LastLogin
$ProcessedGuests = $ProcessedGuests | Sort-Object -Property SortDate -Descending

# Create the final array for the CSV
$FinalExport = $ProcessedGuests | Select-Object DisplayName, Mail, UserPrincipalName, Id, AccountEnabled, CreatedDateTime, LastLogin, "In_Target_Group", "Inactive_180_Days"

# 6. Generate CSV and Base64 Encode it for the Attachment (Contains ALL users)
Write-Output "Creating CSV attachment..."
$CsvString = ($FinalExport | ConvertTo-Csv -NoTypeInformation -Delimiter ";") -join "`r`n"
$CsvBytes = [System.Text.Encoding]::UTF8.GetBytes($CsvString)
$CsvBase64 = [Convert]::ToBase64String($CsvBytes)

# 7. FILTER: Identify accounts that are Stale AND Not in the group
[array]$ActionRequiredAccounts = $ProcessedGuests | Where-Object {
    ($_.Inactive_180_Days -eq "Yes") -and ($_."In_Target_Group" -eq "No")
}

# 8. Build the HTML Body (Contains ONLY Action Required Users)
Write-Output "Building HTML report..."
$TotalGuests = $ProcessedGuests.Count
$TotalActionRequired = $ActionRequiredAccounts.Count

$HtmlBody = @"
<h3>Guest Account Summary</h3>
<p><b>Total Guest Accounts in our Tenant:</b> $TotalGuests</p>
<p><i>The full dataset containing all guests is attached to this email as a CSV. You can filter the "Inactive_180_Days" column to quickly find stale accounts.</i></p>

<hr>
<h4>Action Required: Accounts inactive for 180+ days AND NOT in the "$GroupName" group ($TotalActionRequired found):</h4>
<table border="1" cellpadding="5" style="border-collapse: collapse;">
    <tr style="background-color: #f2f2f2;">
        <th>Name</th>
        <th>User Principal Name</th>
        <th>AccountEnabled</th>
        <th>Last Login</th>
    </tr>
"@

foreach ($Account in $ActionRequiredAccounts) {
    $LoginText = if ($Account.LastLogin -eq "Never") { "<span style='color:red;'><b>Never</b></span>" } else { $Account.LastLogin }
    $HtmlBody += "<tr><td>$($Account.DisplayName)</td><td>$($Account.UserPrincipalName)</td><td>$($Account.AccountEnabled)</td><td>$LoginText</td></tr>"
}
$HtmlBody += "</table>"

# 9. Send the Email via Graph API with Attachment
Write-Output "Sending email..."
$SendMailUrl = "https://graph.microsoft.com/$GraphApiVersion/users/$SharedMailboxAddress/sendMail"

$EmailPayload = @{
    message = @{
        subject = "Action Required: Guest Account 180-Day Inactivity Report"
        body = @{
            contentType = "HTML"
            content = $HtmlBody
        }
        toRecipients = @(
            @{
                emailAddress = @{
                    address = $RecipientAddress
                }
            }
        )
        attachments = @(
            @{
                "@odata.type" = "#microsoft.graph.fileAttachment"
                name = "GuestAccounts_Report.csv"
                contentType = "text/csv"
                contentBytes = $CsvBase64
            }
        )
    }
    saveToSentItems = "false"
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Method Post -Uri $SendMailUrl -Headers $Headers -Body $EmailPayload

Write-Output "Script completed successfully. Found $TotalActionRequired accounts requiring action."
```

Click **Save**, test it using the **Test pane**, and then click **Publish**.

## Step 5: Schedule the Automation
Navigate to `Shared Resources > Schedules` and click `Add a schedule` (e.g., "Weekly on Mondays").

Go back to your published Runbook, click `Link to schedule`, and attach your new schedule.
