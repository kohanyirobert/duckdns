#requires -Version 7.2
#requires -RunAsAdministrator

[CmdletBinding()]
param(
  [string]$Name = "DuckDNS",
  [string]$Path = "\",
  [Parameter(Mandatory)][string]$Domain,
  [TimeSpan]$TaskTimeout = '00:00:30'
)

dynamicparam {
  # Make -Token parameter mandatory if DUCKDNS_TOKEN environment variable is not defined and/or empty.
  $tokenAttribute = New-Object System.Management.Automation.ParameterAttribute
  $tokenAttribute.Mandatory = $env:DUCKDNS_TOKEN ? $false : $true
  $attributeCollection = New-Object System.Collections.ObjectModel.Collection[Attribute]
  $attributeCollection.Add($tokenAttribute)

  $tokenParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Token', [Guid], $attributeCollection)

  $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
  $paramDictionary.Add('Token', $tokenParam)

  return $paramDictionary
}

begin {
  $ErrorActionPreference = 'Stop'
  $Token = $PSBoundParameters.Token ?? [Guid]::Parse($env:DUCKDNS_TOKEN)
}

process {
  & .\uninstall.ps1 -Name $Name -Path $Path

  $triggers = @()
  $class = Get-cimclass MSFT_TaskEventTrigger root/Microsoft/Windows/TaskScheduler
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
    "*>> $env:TEMP\$Name.log"
  )
  if ($VerbosePreference) {
    $scriptArgs += "-Verbose"
  }
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
