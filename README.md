# VixWin Platinum 3.6.3 — GPO / HKCU first-run provisioning

[Русская версия](README.ru.md) · [Technical case study (EN)](https://notes.shandrov.ru/notes/windows/gpo-vixwin-platinum-user-profile-deployment/) · [Практическая статья (RU)](https://notes.shandrov.ru/ru/notes/windows/gpo-vixwin-platinum-user-profile-deployment/)

An **anonymized, intentionally non-deployable example** based on an October 2026 Windows / Active Directory pilot. This repository demonstrates preparing per-user HKCU settings **before the first VixWin launch** in order to use an already existing NAS-hosted image database rather than accidentally starting the new-database wizard.

The example workflow:

- Checks explicit workstation and user allowlists, a mapped NAS drive, an existing database folder, and SHA256 of four private UI registry exports.
- Pre-initializes eight VixWin HKCU values with verified types for a fresh profile.
- Backs up the HKCU branch for an existing profile before modifying it.
- Imports four site-reviewed UI registry subkeys, writes the database path, and records a version marker.
- Logs each run and skips repeated deployment when the required state is healthy.

**NOT READY TO RUN.** The scripts contain placeholders (`ad.example.com`, `CORP`, `PC-01`, `PC-02`, `nas01`, and RFC 5737 documentation address `192.0.2.31`), plus intentionally invalid SHA256 values. The deployment script stops before modifying HKCU until administrators supply audited registry templates and approved private settings. Do not change these placeholders in the public repository.

## Files

- `scripts/Set-VixWinUserSettings.example.ps1` — guarded per-user HKCU initializer and importer.
- `scripts/Invoke-VixWinLogon.example.ps1` — mapped-drive wait (up to 60 seconds) and deployment launcher.
- `scripts/Invoke-VixWinLogon.example.cmd` — user-logon CMD wrapper for GPO.
- `docs/gpo-setup.md` — steps for configuring user/computer policy and verifying results.
- `examples/UI-TEMPLATES-NOT-INCLUDED.md` — why genuine clinical registry exports are excluded.

## Scope and safety

The example does **not** install VixWin, map network drives, create/modify patient databases, access images, manage DICOM devices, or manage NAS ACLs. Run in the **target user's** logon session, **not** as SYSTEM. The optional computer policy `EnableLogonScriptDelay=0` removes the default delay but **does not** ensure synchronous completion of the logon script.

`DatabaseReadOnly=1` was a **site-observed registry value**, not a general recommendation. Validate the values against your own VixWin installation before adapting any code. Production UI `.reg` exports, clinical data, site-specific credentials, addresses and hashes are not included. Restrict write access to SYSVOL/NETLOGON; `-ExecutionPolicy Bypass` is not script authentication. A `-DryRun` may still create local logs.

This public sample is independent of and is **not** the exact production v4 deployed in the case study. It has not been end-to-end tested against a VixWin installation as a standalone distribution.

## License

No open-source license has been selected. All rights reserved unless a license is added.
