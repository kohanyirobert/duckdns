# About

Script to update/clear dynamic IPv4 and IPv6 addresses at [DuckDNS](https://duckdns.org).

**Important**:

1. Assumes [PowerShell 7 (`pwsh.exe`)](https://aka.ms/pwsh) is available on the system
1. `install.ps1` and `uninstall.ps1` must be executed from elevated prompt

## Usage

```pwsh
.\main.ps1 -Domain "your-domain" -Token "your-token" -InterfaceAlias "your-interface-alias"
```

Use the `-Verbose` flag for a chattier output.

## Scheduled Task

### Install

Use `install.ps1` to create a scheduled task that runs on network changes, at logon and startup.

  ```pwsh
  .\install.ps1 -Domain "your-domain" -Token "your-token" -InterfaceAlias "your-interface-alias"
  ```

The task write logs to `$env:TEMP\DuckDNS.log` by default.

### Uninstall

Use `uninstall.ps1` to remove the scheduled task.
