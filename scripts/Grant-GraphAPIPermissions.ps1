# Connect to Entra ID (requires Global Admin or Privileged Role Admin)
Connect-MgGraph -Scopes "AppRoleAssignment.ReadWrite.All", "Application.Read.All"

# The name of your Automation Account's Managed Identity
$AppName = "Your-Automation-Account-Name" # Replace with your Automation Account's Managed Identity name

# Get the Managed Identity Service Principal
$ManagedIdentity = Get-MgServicePrincipal -Filter "displayName eq '$AppName'"

# Get the Microsoft Graph Service Principal
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

    # Assign the role to the Managed Identity
    New-MgServicePrincipalAppRoleAssignment `
        -PrincipalId $ManagedIdentity.Id `
        -ServicePrincipalId $ManagedIdentity.Id `
        -ResourceId $GraphApp.Id `
        -AppRoleId $AppRole.Id

    Write-Host "Assigned $Role to $AppName"
}
