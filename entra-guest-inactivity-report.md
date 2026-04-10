# Azure Automation: 180-Day Guest Inactivity Report

This guide explains how to set up an Azure Automation Account to automatically identify Guest users who have not logged in for over 180 days, and send a summary report via a Shared Mailbox.

This solution operates entirely headlessly using a **System-Assigned Managed Identity** and the **Microsoft Graph API**.

## Architecture diagram

<div class="mermaid">
graph TD
    %% Define Styling
    classDef azure fill:#0072C6,stroke:#fff,stroke-width:2px,color:#fff;
    classDef entra fill:#0078D4,stroke:#fff,stroke-width:2px,color:#fff;
    classDef exchange fill:#00A4EF,stroke:#fff,stroke-width:2px,color:#fff;

    subgraph Azure Subscription
        AA[Azure Automation Account]:::azure
        MI[System-Assigned Managed Identity]:::azure
        RB[PowerShell Runbook & Schedule]:::azure
    end

    subgraph Microsoft Entra ID
        Graph[Microsoft Graph API]:::entra
        Guests[Guest User Profiles & Sign-in Logs]:::entra
        Group[Entra ID Group: Guest_Accounts]:::entra
        Perms[[Application Permissions]]:::entra
    end

    subgraph Exchange Online
        Mailbox[Disabled Shared Mailbox]:::exchange
        Recipient[IT Admin Inbox]:::exchange
    end

    %% Relationships and Data Flow
    AA -->|Hosts| RB
    AA -->|Enables| MI
    MI -.->|Granted| Perms
    Perms -.->|Authorizes| Graph
    
    RB -->|1. Requests Access Token via| MI
    RB -->|2. Queries Data via| Graph
    Graph -->|Reads| Guests
    Graph -->|Reads| Group
    
    RB -->|3. Processes Data & Encodes CSV| RB
    
    RB -->|4. Submits Email Payload via| Graph
    Graph -->|Routes message through| Mailbox
    Mailbox -->|Delivers HTML + CSV| Recipient
</div>

<script type="module">
  import mermaid from '[https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs](https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs)';
  mermaid.initialize({ startOnLoad: true });
</script>

---

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
1. In your Automation Account, go to **Process Automation > Runbooks**.
2. Click **Create a runbook**. 
3. Name it (e.g., `Get-StaleGuestAccounts`), set the Runbook type to **PowerShell**, and set the Runtime version to **5.1** (or 7.2).
4. Download the script from this repository: 
   👉 **[Get-StaleGuestAccounts.ps1](Get-StaleGuestAccounts.ps1)**
5. Paste the code into the Azure Automation editor. *(Remember to update the configuration variables at the top of the script with your specific Group ID and email addresses).*
6. Click **Save**, test it using the **Test pane**, and then click **Publish**.

## Step 5: Schedule the Automation
Navigate to **Shared Resources > Schedules** and click **Add a schedule** (e.g., "Weekly on Mondays").

Go back to your published Runbook, click **Link to schedule**, and attach your new schedule.
