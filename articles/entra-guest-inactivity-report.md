# Azure Automation: 180-Day Guest Inactivity Report

This guide explains how to set up an Azure Automation Account to automatically identify Guest users who have not logged in for over 180 days, and send a summary report via a Shared Mailbox.

This solution operates entirely headlessly using a **System-Assigned Managed Identity** and the **Microsoft Graph API**.

## Prerequisites
* An active Azure Subscription.
* Global Administrator or Privileged Role Administrator rights (to assign Graph API permissions).
* A Shared Mailbox in Exchange Online.
* The Object ID of an Entra ID Group (if you want to filter out specific guests).

---

## Architecture diagram

<div style="padding: 20px; background: #fdfdfd; border-radius: 12px; border: 1px solid #eee; transition: transform 0.3s ease; box-shadow: 0 10px 30px rgba(0,0,0,0.05);" 
     onmouseover="this.style.transform='scale(1.02)'" 
     onmouseout="this.style.transform='scale(1)'">
  
  <a href="/images/architecture_diagram.png" target="_blank">
    <img src="/images/architecture_diagram.png" alt="Architecture Diagram" style="width: 100%; border-radius: 8px;">
  </a>
  
</div>

<p style="text-align: center; color: #666; font-size: 0.9em; margin-top: 15px;">
  🔍 <i>Click image to open full-resolution version in a new tab</i>
</p>

## Step 1: Create the Azure Automation Account
1. Log into the <a href="https://portal.azure.com" target="_blank" rel="noopener noreferrer">Azure Portal</a> and search for **Automation Accounts**.
2. Click **Create**, fill in your resource group and naming details, and deploy the resource.

## Step 2: Enable the Managed Identity
1. Navigate to your new Automation Account.
2. On the left menu, under **Account Settings**, select **Identity**.
3. Under the **System assigned** tab, set the Status to **On** and click **Save**.
4. Note the **Object (principal) ID** that is generated.

## Step 3: Grant Graph API Permissions
Because you cannot assign Microsoft Graph *Application* permissions to a Managed Identity via the Azure Portal GUI, you must use PowerShell.

Open an administrative PowerShell console, ensure the `Microsoft.Graph` module is installed, download and run the script from this repository: 
   👉 <a href="https://github.com/AzureBrother/AzureBrother.github.io/blob/main/scripts/Grant-GraphAPIPermissions.ps1" target="_blank" rel="noopener noreferrer">Grant-GraphAPIPermissions.ps1</a>

> Be sure to replace `$AppName` with the exact name of your Automation Account.

## Step 4: Create the Runbook
1. In your Automation Account, go to **Process Automation > Runbooks**.
2. Click **Create a runbook**. 
3. Name it (e.g., `Get-StaleGuestAccounts`), set the Runbook type to **PowerShell**, and set the Runtime version to **5.1** (or 7.2).
4. Download the script from this repository: 
   👉 <a href="https://github.com/AzureBrother/AzureBrother.github.io/blob/main/scripts/Get-StaleGuestAccounts.ps1" target="_blank" rel="noopener noreferrer">Get-StaleGuestAccounts.ps1</a>
5. Paste the code into the Azure Automation editor. 
6. Click **Save**, test it using the **Test pane**, and then click **Publish**.

> Remember to update the configuration variables at the top of the script with your specific Group ID and email addresses.

## Step 5: Schedule the Automation
Navigate to **Shared Resources > Schedules** and click **Add a schedule** (e.g., "Weekly on Mondays").

Go back to your published Runbook, click **Link to schedule**, and attach your new schedule.
