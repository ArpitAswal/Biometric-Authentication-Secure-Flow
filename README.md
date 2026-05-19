# Premium Biometric Authentication App

A Flutter application demonstrating standard biometric authentication (Fingerprint / Face ID) patterns, featuring "Remember Me" (Soft Logout) and account removal (Hard Logout) capabilities.

## Architecture & Authentication Flows

### Biometric Flow (Multi-User Single-Device Handling)

Since mobile operating systems (iOS Secure Enclave & Android Keystore) verify whether the *device owner* has authenticated but do not identify *which* specific user is logging in, this application implements a standard single-active-biometric pattern. 

Only the **last user who logged in and enabled biometrics** can log in via biometric authentication. Logging in with a different account automatically wipes the previously stored biometric configuration to ensure security.

```mermaid
graph TD
    A[Start: App Opened] --> B{Saved Biometric Credentials Exist?}
    B -- Yes --> C[Show Quick Biometric Login]
    B -- No --> D[Show Manual Login Screen]
    
    C --> E[User taps Biometric Login]
    E --> F[Fingerprint/Face Scan]
    F -- Success --> G[Decrypt Token -> Log into Saved Account]
    F -- Fail --> D
    
    D --> H[User logs in manually]
    H --> I{Is this a different user from saved account?}
    I -- Yes --> J[Delete old biometric token & settings]
    I -- No --> K[Proceed]
    J --> K
    K --> L[Save new User's credentials to Secure Storage]
    L --> M[App Dashboard]
```

---

### Scenario 1: User A enables biometrics, User B logs in manually (does not enable biometrics)

| Step | Action | Secure Storage State | Login Screen Behavior |
| :--- | :--- | :--- | :--- |
| **1** | **User A** logs in and enables biometrics. | `savedUsername` = `"User A"`<br>`biometricEnabled` = `true`<br>`token` = `"token_A"` | — |
| **2** | **User A** logs out (Soft Logout). | `savedUsername` = `"User A"`<br>`biometricEnabled` = `true`<br>`token` = `"token_A"` | **Quick Biometric Sign-In** button is visible. |
| **3** | **User B** logs in manually. | `savedUsername` = `"User B"`<br>`biometricEnabled` = `false`<br>`token` = `null` | Previous biometric setup for User A is deleted on detection of a different user. |
| **4** | **User B** logs out (Soft Logout). | `savedUsername` = `"User B"`<br>`biometricEnabled` = `false`<br>`token` = `null` | **Quick Biometric Sign-In** button is hidden. |

---

### Scenario 2: Both User A and User B enable biometrics

| Step | Action | Secure Storage State | Login Screen Behavior |
| :--- | :--- | :--- | :--- |
| **1** | **User A** logs in and enables biometrics. | `savedUsername` = `"User A"`<br>`biometricEnabled` = `true`<br>`token` = `"token_A"` | — |
| **2** | **User A** logs out (Soft Logout). | `savedUsername` = `"User A"`<br>`biometricEnabled` = `true`<br>`token` = `"token_A"` | **Quick Biometric Sign-In** button is visible. |
| **3** | **User B** logs in manually. | `savedUsername` = `"User B"`<br>`biometricEnabled` = `false`<br>`token` = `null` | User A's configurations are cleared. |
| **4** | **User B** enables biometrics in settings. | `savedUsername` = `"User B"`<br>`biometricEnabled` = `true`<br>`token` = `"token_B"` | — |
| **5** | **User B** logs out (Soft Logout). | `savedUsername` = `"User B"`<br>`biometricEnabled` = `true`<br>`token` = `"token_B"` | **Quick Biometric Sign-In** button is visible for **User B**. |

---

## Soft Logout vs. Hard Logout

1. **Soft Logout (Logout)**
   - Triggered via the **Logout** button.
   - Clears the active in-memory session.
   - Retains the token, username, and biometric configuration in Secure Storage.
   - Allows the user to quickly log back in with biometrics on the login page.

2. **Hard Logout (Remove Account)**
   - Triggered via the **Remove Account from Device** (or **Forget Saved Account**) button.
   - Completely deletes all credentials from Secure Storage.
   - Disables biometric sign-in so that the next user must input their email/password manually.
