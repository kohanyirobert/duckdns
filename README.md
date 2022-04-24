# About

Script to update dynamic IPv4 and/or IPv6 addresses at [DuckDNS](https://duckdns.org).

**Important**: the script assumes [PowerShell 7 (`pwsh.exe`)](https://aka.ms/pwsh) is available on the system.

## Usage

### Direct Execution

```pwsh
.\main.ps1 -Domain "your-domain" -Token "your-token" -InterfaceAlias "your-interface-alias" -IPv6
```

Use the `-Verbose` flag for a chattier output.

### Scheduled Task

Use `task.ps1` to create a scheduled task that runs on network changes, at logon and startup

  ```pwsh
  .\task.ps1 -Domain "your-domain" -Token "your-token" -InterfaceAlias "your-interface-alias" -IPv6
  ```

The task write logs to `$env:TEMP\DuckDNS.log`.
