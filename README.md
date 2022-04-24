# About

Script to update/clear dynamic IPv4 and IPv6 addresses at [DuckDNS](https://duckdns.org).

**Important**: execute `install.ps1` and `uninstall.ps1` from an elevated prompt.

## Usage

```pwsh
.\main.ps1 -Domain "your-domain" -Token "your-token"
```

Use the `-Verbose` flag for a chattier output.

## Scheduled Task

### Install

Use `install.ps1` to create a scheduled task that runs on network changes, at logon and startup.

  ```pwsh
  .\install.ps1 -Domain "your-domain" -Token "your-token"
  ```

The task write logs to `$env:TEMP\DuckDNS.log` by default.

### Uninstall

Use `uninstall.ps1` to remove the scheduled task.
