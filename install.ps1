param(
  [string]$Name = "DuckDNS",
  [string]$Path = "\",
  [string]$Domain,
  [string]$Token,
  [string]$InterfaceAlias,
  [switch]$Verbose
)

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

$timeout = (New-TimeSpan -Seconds 3)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -ExecutionTimeLimit $timeout
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
  "-InterfaceAlias", $InterfaceAlias,
  "*>> $env:TEMP\$Name.log"
)
if ($Verbose) {
  $scriptArgs += "-Verbose"
}
$action = New-ScheduledTaskAction `
  -WorkingDirectory $PWD `
  -Execute "pwsh.exe" `
  -Argument ($scriptArgs -Join " ")
Register-ScheduledTask `
  -TaskName $Name `
  -TaskPath $Path `
  -Action $action `
  -Trigger $triggers `
  -Principal $principal `
  -Settings $settings
