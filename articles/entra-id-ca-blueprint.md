## 🛡️ Your Conditional Access is Outdated. Here’s the 2026 Zero Trust Blueprint.

If you open your Microsoft Entra ID portal and see a graveyard of "temporary" Conditional Access (CA) policies, overlapping rules, and legacy configurations, you aren't alone. Most IT teams built their CA policies years ago and just kept adding to the pile. 

But the threat landscape has shifted. Hackers are bypassing basic MFA, exploiting legacy protocols, and targeting unmanaged devices. 

In my latest episode, I wiped the slate clean and rebuilt a **Zero Trust Conditional Access Architecture** from the ground up, using only **Entra ID P1** features. No expensive P2 licenses—just solid, logical security.

### 📺 Watch the Full Breakdown

[![Watch the video](https://img.youtube.com/vi/rp_MARpOai4/maxresdefault.jpg)](https://youtu.be/rp_MARpOai4)

---

## 🛑 Stop Before You Build: The Prerequisites

Before implementing this blueprint, you must ensure your foundation is solid:

1. **Kill SMS & Voice MFA:** These are highly vulnerable to SIM-swapping and Adversary-in-the-Middle (AiTM) attacks. Push your users toward Microsoft Authenticator, FIDO2/Passkeys, or Certificate-Based Authentication.
2. **The "Break Glass" Account:** Never exclude a named user. Always create a dedicated, highly secure Emergency Access Account and exclude it from *every* CA policy so you never lock yourself out of your tenant.
3. **Report-Only Mode is Mandatory:** Never toggle a new CA policy to "On" right away. Leave it in "Report-Only" for at least 48 hours and use the **What-If** tool to verify your logic.

---

## 🏗️ The 2026 CA Policy Architecture

To keep things clean, we use a strict naming convention: **CA0** for All Users, **CA1** for Admins, and **CA2** for Guests. Here are the 7 definitive policies you need.

### Phase 1: Baseline Authentication & Protocol Blocks

#### 1. CA01 - All Users - All Apps - Require MFA
The foundation of your security. Every standard user must prove who they are.
* **Target Users:** All Users (Exclude: Break Glass Account, specific sync service accounts)
* **Target Apps:** All Resources
* **Grant Control:** Require Multifactor Authentication (Configure your tenant to enforce modern, passwordless/non-SMS methods).

#### 2. CA02 - All Users - All Apps - Block Device Code Flow
Device code flow is easily abused by attackers tricking users into authenticating remote sessions.
* **Target Users:** All Users (Exclude: Break Glass Account)
* **Target Apps:** All Resources
* **Conditions:** Client Apps > Include **Device code flow** and **Authentication transfer**.
* **Grant Control:** Block

#### 3. CA03 - All Users - All Apps - Block Legacy Authentication
Legacy protocols (like POP3/IMAP4) do not support MFA. They must be shut down.
* **Target Users:** All Users (Exclude: Break Glass Account)
* **Target Apps:** All Resources
* **Conditions:** Client Apps > Include **Exchange ActiveSync clients** and **Other clients**.
* **Grant Control:** Block

---

### Phase 2: Taming BYOD and Untrusted Devices

#### 4. CA04 - All Users - All Apps - No Persistent Browser Session (Untrusted Endpoints)
If a user logs into a home PC and forgets to log out, the next person using that PC shouldn't have access to your corporate data.
* **Target Users:** All Users (Exclude: Break Glass Account)
* **Target Apps:** All Resources
* **Conditions:**
  * Client Apps: Browser
  * Filter for Devices: Include `device.isCompliant -ne True` (Excludes Hybrid/Entra-joined compliant devices).
* **Session Control:** Sign-in frequency (12 hours) AND **Never persistent**.

#### 5. CA05 - All Users - Office 365 - Allow Web-Only for BYOD
This is the ultimate BYOD security trick. We block the Outlook/Teams desktop apps on personal PCs, forcing users into the web browser where data can't be easily downloaded.
* **Target Users:** All Users (Exclude: Break Glass Account)
* **Target Apps:** Office 365
* **Conditions:**
  * Device Platforms: Include Any Device. Exclude Android & iOS (Handle phones via App Protection Policies/MAM instead).
  * Client Apps: Mobile apps and desktop clients. *(Do not check Browser)*.
  * Filter for Devices: Include `device.isCompliant -ne True -and device.trustType -ne "ServerAD"`
* **Grant Control:** Block

---

### Phase 3: Elevated Risk & External Access

#### 6. CA10 - Admins - All Apps - Require Compliant Device or Phishing-Resistant MFA
Admins hold the keys to the kingdom. They require a much higher standard of security.
* **Target Users:** Directory Roles (Global Admin, Privileged Role Admin, etc.) (Exclude: Break Glass Account)
* **Target Apps:** All Resources
* **Grant Control:** Require one of the selected controls: **Require authentication strength (Phishing-Resistant MFA)** OR **Require device to be marked as compliant**.
* **Session Control:** Sign-in frequency (4 hours) AND Never persistent.

#### 7. CA20 - Guest Users - Office 365 - Require MFA
Don't let external collaborators be your weak link.
* **Target Users:** All Guest and external users
* **Target Apps:** Office 365
* **Grant Control:** Require MFA
* **Session Control:** Sign-in frequency (8 hours).

---

### 🚀 Ready to Secure Your Cloud?

Every environment is unique, so use this blueprint as your foundation and adapt it to your specific compliance needs. Always check the **Coverage Blade** in Entra ID to ensure no users are falling through the cracks!

If you found this guide helpful, make sure to 👉 <a href="https://www.youtube.com/@AzureBrothers" target="_blank" rel="noopener noreferrer">Subscribe to Azure Brother on YouTube</a> for more cloud architecture deep dives. Remember, when it comes to Azure, you always got your brother in the cloud! ☁️
