# Private registry templates are deliberately excluded

The demonstration script requires four reviewed templates on a private, read-only NETLOGON path:

- Customize.reg
- Toolbar.reg
- Toolbox.reg
- UserInterface.reg

Do **not** commit genuine clinical workstation registry exports. Review every value for patient, site, machine and identity information. Generate SHA256 hashes locally and insert them into a privately maintained deployment variant. The public hashes are all zeroes and therefore fail closed.
