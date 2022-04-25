#requires -Version 5.1
#requires -RunAsAdministrator

using namespace System.Collections.ObjectModel
using namespace System.Management.Automation

[CmdletBinding()]
param(
  [string]
  $Name = "DuckDNS",

  [string]
  $Path = "\",

  [Parameter(Mandatory)]
  [string]
  $Domain,

  [Parameter(Mandatory)]
  [ValidateSet('IPv4', 'IPv6')]
  [string]
  $Operation,

  [TimeSpan]
  $TaskTimeout = '00:00:30'
)

dynamicparam {
  # Make -Token parameter mandatory if DUCKDNS_TOKEN environment variable is not defined and/or empty.
  $tokenAttribute = New-Object ParameterAttribute
  $tokenAttribute.Mandatory = if ($env:DUCKDNS_TOKEN) { $false } else { $true }
  $attributeCollection = New-Object Collection[Attribute]
  $attributeCollection.Add($tokenAttribute)

  $tokenParam = New-Object RuntimeDefinedParameter('Token', [Guid], $attributeCollection)

  $paramDictionary = New-Object RuntimeDefinedParameterDictionary
  $paramDictionary['Token'] = $tokenParam

  return $paramDictionary
}

begin {
  $ErrorActionPreference = 'Stop'
  $Token = if ($PSBoundParameters.Token) { $PSBoundParameters.Token } else { [Guid]::Parse($env:DUCKDNS_TOKEN) }
  Write-Verbose "Token: $Token"
}

process {
  & .\uninstall.ps1 -Name $Name -Path $Path

  $triggers = @()
  $class = Get-cimclass MSFT_TaskEventTrigger root/Microsoft/Windows/TaskScheduler -Verbose:$false
  $networkChangeTrigger = $class | New-CimInstance -ClientOnly
  $networkChangeTrigger.Enabled = $true
  $networkChangeTrigger.Subscription = '<QueryList>
    <Query Id="0" Path="Microsoft-Windows-NetworkProfile/Operational">
      <Select Path="Microsoft-Windows-NetworkProfile/Operational">
        *[System[Provider[@Name=''Microsoft-Windows-NetworkProfile''] and EventID=10000]]
      </Select>
    </Query>
  </QueryList>'
  $triggers += $networkChangeTrigger
  $resumeFromSleepTrigger = $class | New-CimInstance -ClientOnly
  $resumeFromSleepTrigger.Enabled = $true
  $resumeFromSleepTrigger.Subscription = '<QueryList>
    <Query Id="0" Path="System">
      <Select Path="System">
        *[System[EventID=107]]
      </Select>
    </Query>
  </QueryList>'
  $triggers += $resumeFromSleepTrigger
  $triggers += (New-ScheduledTaskTrigger -AtStartup)
  $triggers += (New-ScheduledTaskTrigger -AtLogon)

  $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -ExecutionTimeLimit $TaskTimeout
  $principal = New-ScheduledTaskPrincipal -UserId $(whoami) -LogonType S4U

  $scriptArgs = @(
    "-NoLogo",
    "-NonInteractive",
    "-NoProfile",
    # Must have backslash to indicate script execution
    # Must use -Command, because -File eats up parameters to its right
    "-Command", ".\main.ps1",
    "-Domain", $Domain,
    "-Token", $Token,
    "-Operation", $Operation,
    "*>> $env:TEMP\$Name.log"
  )
  if ($VerbosePreference) {
    $scriptArgs += "-Verbose"
  }
  Write-Verbose "ScriptArgs: $scriptArgs"
  $action = New-ScheduledTaskAction `
    -WorkingDirectory $PWD `
    -Execute "powershell.exe" `
    -Argument ($scriptArgs -Join " ")
  Register-ScheduledTask `
    -TaskName $Name `
    -TaskPath $Path `
    -Action $action `
    -Trigger $triggers `
    -Principal $principal `
    -Settings $settings
}
