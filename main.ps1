param(
  [string]$Domain,
  [string]$Token,
  [string]$InterfaceAlias,
  [switch]$Clear,
  [switch]$Verbose,
  [TimeSpan]$Timeout = '00:00:03'
)

function Get-IPv6Address([string]$InterfaceAlias) {
  return (
    Get-NetIPAddress `
      -InterfaceAlias $InterfaceAlias `
      -AddressFamily IPv6 `
      -Type Unicast `
      -PrefixOrigin RouterAdvertisement `
      -SuffixOrigin Link `
      -ErrorAction Stop
    ).IPAddress
}

function Get-ISODate() {
  return Get-Date -UFormat +%Y-%m-%dT%H:%M:%S
}

function Write-Log([string]$Message) {
  Write-Output "$(Get-ISODate) - $Message"
}

$uri = "https://www.duckdns.org/update?token=$Token&domains=$Domain&ip="
try {
  $uri += "&ipv6=$(Get-IPv6Address $InterfaceAlias)"
} catch {
  $uri += "&ipv6="
}
if ($Verbose) {
  $uri += "&verbose=true"
}
if ($Clear) {
  $uri += "&clear=true"
}
$response = Invoke-WebRequest -TimeoutSec $Timeout.Seconds $uri
if ($Verbose) {
  Write-Log "START"
  Write-Log "REQUEST"
  Write-Log $response.BaseResponse.RequestMessage
  Write-Log "RESPONSE"
  Write-Log $response.RawContent
  Write-Log "END"
}
else {
  Write-Log "$(($response.RawContent -split "`r?`n")[-1]) - $uri"
}
