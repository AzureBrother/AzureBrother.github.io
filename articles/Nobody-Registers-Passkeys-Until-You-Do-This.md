# Nobody Registers Passkeys... Until You Do This | Entra ID Registration Campaigns

Let’s be honest: most organizations know they should move to Passkeys. Microsoft, Google, Apple, and all major tech companies are pushing toward a passwordless future. Security teams love them because they are phishing-resistant by design, users don't have to remember passwords, type complex codes, or approve endless MFA notification fatigue.

There’s just one major roadblock: **users don't really register passkeys on their own.** 

Instead of waiting passively for users to discover and set up passkeys in their security info panel, Microsoft built a mechanism to proactively guide them: **Registration Campaigns**. In my latest video, I walk through how to configure these campaigns to enforce and streamline Passkey adoption.

If you prefer a visual walkthrough, you can watch the full video on the **Azure Brother** YouTube channel here:

[![Watch the video](https://img.youtube.com/vi/J0CaUcqbvNQ/maxresdefault.jpg)](https://www.youtube.com/embed/J0CaUcqbvNQ)

---

## Prerequisites & Understanding the Options

Before setting up a registration campaign, keep a few critical administrative rules in mind:
1. **Enable the Authentication Method First:** Users must explicitly be enabled for the target authentication method (Passkeys or Microsoft Authenticator) under your tenant authentication policies *before* they can become eligible for a registration nudge.
2. **One Method at a Time:** A registration campaign can only target **one** authentication method at a time. You can target Passkeys or the Authenticator app, but not both simultaneously.

When configuring the campaign in the Entra portal, you are presented with three main toggle states: **Disabled**, **Enabled**, and **Microsoft Managed**.

* **Enabled Mode:** Grants you full administrative customization. You can choose your target authentication method (Passkeys vs. Authenticator app), configure how many days users are allowed to snooze the prompt (between 0 and 14 days), and choose whether to limit the total number of allowed snoozes.
* **Microsoft Managed Mode:** Hands the steering wheel over to Microsoft. The target authentication method automatically defaults to Passkeys, the snooze duration locks to 1 day, and the snooze limit disables (forcing continuous reminders).

## Configuring a Custom Campaign

To maintain fine-grained control over user experience and avoid overwhelming employees with daily prompts, we configure a custom **Enabled** campaign targeting a specific security group (e.g., our Pilot Passkey group):

1. **Target Method:** Set to **Passkeys**.
2. **Snooze Duration:** Set to **3 days** (meaning if a user clicks "Not Now", they won't be bothered again for 72 hours).
3. **Limited Snoozes:** Enabled, with a strict ceiling (e.g., max 3 snoozes). Once a user exhausts their allowed skips, they are **forced** to complete the Passkey registration before they can proceed past the login prompt.

## The User Experience

When a target user (let's call him Eric) logs into his account, even if his system-preferred MFA method is currently phone app notifications, the registration campaign triggers seamlessly during sign-in:

1. **The Nudge:** Eric is greeted with a prompt saying: *"Let's keep your account more secure."* He has the option to click **Not Now** (snooze) or **Next**.
2. **Passkey Creation:** Clicking Next presents the prompt to *“Create a passkey to sign in to your account. No apps, passwords, or codes required.”*
3. **Storage Selection:** Eric can choose where to save the passkey, whether on his local Windows device, an iOS/Android device, or a physical security key. In our scenario, he binds it directly to his **Windows device**.
4. **Biometric Confirmation:** After confirming the URL (`login.microsoft.com`), Windows prompts for a biometric scan (Windows Hello facial recognition or PIN), saves the private key locally (which never leaves the device), and registers the public key counterpart in Entra ID.

Immediately after completion, checking the user's authentication methods reveals two things:
* The new passkey is registered and tied to the device.
* **System-Preferred MFA automatically updates** to the strongest available method (`FIDO2` / Passkey).

## Why Passkeys Change the Login Game

Beyond being the most phishing-resistant authentication vector available, passkeys drastically improve daily UX. As shown in the video, users no longer even need to type their username. Clicking the username field automatically surfaces local passkeys. A quick facial scan or PIN entry later, and the user is instantly and securely signed in.

---

## Community Notes & Comments Deep Dive

Following the release of this video, several viewers and community members raised fantastic questions and edge-case scenarios worth addressing in your deployment strategy:

### 1. The "Interrupt Fatigue" and Productivity Balance
* **The Community Feedback:** Several admins noted that setting the snooze limit too aggressively (e.g., forcing registration on day one with 0 snoozes) can cause panic and a spike in helpdesk tickets if users are caught in the middle of urgent tasks. 
* **The Recommendation:** Utilize the granular snooze configuration shown in the video (e.g., a 3-day snooze window with a cap of 3 skips). This gives users enough breathing room to register on their own schedule before the mandatory block kicks in, drastically reducing support desk load.

### 2. Cross-Device Passkeys vs. Device-Bound WHfB
* **The Community Feedback:** Viewers asked whether a passkey registered via a campaign on a Windows laptop can be used on other machines.
* **The Recommendation:** Make sure users understand the distinction between device-bound passkeys (like Windows Hello for Business or TPM-backed FIDO2 keys) and multi-device passkeys (synced via iCloud Keychain or Google Password Manager, or stored in the Microsoft Authenticator app). If a user registers a passkey bound to their corporate laptop's TPM, it stays on that laptop. For cross-device cloud access, pairing this strategy with Authenticator app passkeys is essential.

***

*If this technical deep dive was useful for you, let me know in the comments on YouTube. And remember, when it comes to Azure, you always got your brother in the cloud.*
