# AVD SSO Troubleshooter

Read-only PowerShell diagnostics for Azure Virtual Desktop single sign-on (SSO) issues.

This toolkit helps identify why AVD SSO is failing or prompting users for credentials, especially when troubleshooting confusing combinations of:

- `enablerdsaadauth`
- legacy `targetisaadjoined`
- Entra-joined session hosts
- hybrid-joined session hosts
- AD DS joined session hosts
- AVD agent health
- Conditional Access / consent / Entra RDP authentication prerequisites
- Windows App / Remote Desktop credential prompts

The scripts do **not** change Azure, Microsoft Entra ID, the host pool, or the VM. They collect evidence and produce a local JSON/Markdown report with findings and recommended next actions.

## Repository contents

| File | Purpose |
| --- | --- |
| `Test-AvdSsoCloud.ps1` | Run from Azure Cloud Shell or an admin workstation to inspect AVD host pool and Azure-side configuration. |
| `Test-AvdSsoSessionHost.ps1` | Run inside an AVD session host VM to inspect join state, AVD agent services, event logs, and endpoint reachability. |
| `Invoke-AvdSsoTroubleshooter.ps1` | Convenience wrapper for cloud-side or session-host mode. |

## Quick start: cloud-side check

Run this from Azure Cloud Shell or a workstation with Az PowerShell installed.

```powershell
Connect-AzAccount

./Test-AvdSsoCloud.ps1 `
  -SubscriptionId '<subscription-id>' `
  -ResourceGroupName '<resource-group-name>' `
  -HostPoolName '<host-pool-name>' `
  -Markdown
```

Minimum Azure permissions:

- Subscription/resource group Reader
- Desktop Virtualization Reader, or equivalent read access to the host pool and session hosts
- VM read access if you want extension checks

Optional Entra checks require Microsoft Graph PowerShell and directory/policy read permissions:

```powershell
./Test-AvdSsoCloud.ps1 `
  -ResourceGroupName '<resource-group-name>' `
  -HostPoolName '<host-pool-name>' `
  -IncludeEntraChecks `
  -Markdown
```

## Quick start: session-host check

Run this in an elevated PowerShell session on the AVD session host VM.

```powershell
./Test-AvdSsoSessionHost.ps1 -Markdown
```

For hybrid or AD DS joined environments, include domain controllers to test Kerberos and LDAP reachability:

```powershell
./Test-AvdSsoSessionHost.ps1 `
  -AdditionalDomainControllers 'dc01.contoso.com','dc02.contoso.com' `
  -Markdown
```

## Wrapper usage

Cloud mode:

```powershell
./Invoke-AvdSsoTroubleshooter.ps1 `
  -ResourceGroupName '<resource-group-name>' `
  -HostPoolName '<host-pool-name>' `
  -Markdown
```

Session-host mode:

```powershell
./Invoke-AvdSsoTroubleshooter.ps1 -SessionHost -Markdown
```

## What the cloud script checks

- Host pool custom RDP properties:
  - `enablerdsaadauth:i:1`
  - legacy `targetisaadjoined:i:1`
  - `enablecredsspsupport`
- Host pool metadata.
- Session host registration and availability.
- VM power state and extensions when permissions allow.
- AADLoginForWindows extension hints.
- Optional Microsoft Graph / Entra checks:
  - tenant-level Entra RDP authentication verification hints
  - active Conditional Access policy presence

## What the VM script checks

- `dsregcmd /status` join state.
- Entra-only vs hybrid vs AD DS only classification.
- Current Windows identity context, masked by default.
- AVD agent services:
  - `RDAgentBootLoader`
  - `RDAgent`
  - `TermService`
- Registry/policy indicators for RDP, CredSSP, Windows Hello for Business, and Cloud Kerberos.
- Recent relevant event logs:
  - `Microsoft-Windows-AAD/Operational`
  - Terminal Services logs
  - Remote Desktop Services logs
  - Application/System logs
- Endpoint reachability for Entra and AVD services.
- Optional Kerberos/LDAP reachability to specified domain controllers.

## Output

Each run writes:

- Console summary
- JSON evidence report
- Optional Markdown report with `-Markdown`

The report includes:

- Overall status:
  - `Healthy`
  - `Likely Misconfigured`
  - `Partially Configured`
  - `Needs Manual Review`
- Detected scenario
- Top likely cause
- Findings with severity, evidence, impact, and recommendation

Example finding:

```text
Finding: Host pool is not configured for modern Entra RDP authentication
Severity: High
Evidence: enablerdsaadauth:i:1 was not found in customRdpProperty
Impact: Users can be prompted for credentials or fail Windows sign-in
Recommendation: Add enablerdsaadauth:i:1 to the host pool RDP properties after review
```

## Privacy and safety

- The scripts are read-only.
- Generated reports are local files only.
- Tokens, bearer strings, passwords, keys, and secrets are redacted.
- User identity values are masked by default.
- Use `-VerboseIdentity` only if you intentionally need full local identity values in the report.
- Generated `avd-sso-*.json` and `avd-sso-*.md` reports are ignored by git.

## Suggested operating workflow

1. Run `Test-AvdSsoCloud.ps1` against the affected host pool.
2. Run `Test-AvdSsoSessionHost.ps1` on one affected session host.
3. Compare the top findings:
   - if cloud-side RDP flags are wrong, fix host pool configuration first;
   - if VM join state is wrong, fix device registration/join before changing RDP flags;
   - if AVD agent is unhealthy, repair the agent before SSO-specific troubleshooting;
   - if Conditional Access is suspected, correlate with Entra sign-in logs for the affected user and timestamp.
4. Make one controlled change at a time and rerun both scripts.

## Notes

This project is intended as a practical triage helper, not a replacement for Microsoft documentation or production change review. Always validate recommended remediation in a test host pool before applying to production.
