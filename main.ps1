param(
  [string]$Domain,
  [string]$Token,
  [switch]$Clear,
  [switch]$Verbose,
  [TimeSpan]$RequestTimeout = '00:00:03'
)

function Get-ActiveInterfaceAlias() {
    $aliases = @(Get-NetAdapter -Physical | Where-Object {$_.Status -eq "Up"} | ForEach-Object {$_.InterfaceAlias})
    if ($aliases) {
      if ($aliases.Count -eq 1) {
        return $aliases[0]
      } else {
        throw "Found more than one active physical network adapters: $($aliases -join ', ')"
      }
    } else {
      throw "No active physical network adapter found"
    }
}

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
  $alias = Get-ActiveInterfaceAlias
  $ipv6 = Get-IPv6Address $alias
  $uri += "&ipv6=$ipv6"
} catch {
  $uri += "&ipv6="
}
if ($Verbose) {
  $uri += "&verbose=true"
}
if ($Clear) {
  $uri += "&clear=true"
}
$response = Invoke-WebRequest -TimeoutSec $RequestTimeout.Seconds $uri
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
