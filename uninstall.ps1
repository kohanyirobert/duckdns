param(
  [string]$Name = "DuckDNS",
  [string]$Path = "\"
)

Unregister-ScheduledTask `
  -TaskName $Name `
  -TaskPath $Path `
  -Confirm:$false `
  -ErrorAction Ignore
