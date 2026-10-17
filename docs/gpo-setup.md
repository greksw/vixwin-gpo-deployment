# GPO setup (sanitized reference)

1. Scope a **user** GPO to a narrowly reviewed AD user group. Leave Authenticated Users with Read, grant the target user group Apply.
2. Add the example CMD script under User Configuration > Policies > Windows Settings > Scripts > Logon, after copying and auditing all scripts to a protected NETLOGON folder.
3. Provide the SMB drive mapping through a separate user GPO; the launcher does not create Z:.
4. Optionally use a **computer** GPO filtered to explicitly approved workstations with `HKLM\SOFTWARE\Policies\Microsoft\Windows\System\EnableLogonScriptDelay` DWORD `0`. This removes the delay but does not ensure synchronous completion.
5. Validate in a small pilot: `whoami`, `gpresult /scope user /r`, launcher/deployment logs, mapping of Z: and VixWin first launch.
6. Only after pilot verification allow a broader AD user group to Apply.

**CAUTION:** The public PowerShell files contain example identities and deliberately invalid hashes; do not link them to production GPOs. Ensure logon is in the actual target user context; do not run as SYSTEM.
