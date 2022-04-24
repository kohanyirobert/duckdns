param(
  [string]$Domain,
  [string]$Token,
  [string]$InterfaceAlias,
  [switch]$IPv4,
  [switch]$IPv6,
  [switch]$Verbose
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

$uri = "https://www.duckdns.org/update?token=$Token&domains=$Domain"
if ($Verbose) {
  $uri += "&verbose=true"
}
if ($IPv4) {
  $uri += "&ip="
}
if ($IPv6) {
  $uri += "&ipv6=$(Get-IPv6Address $InterfaceAlias)"
}
if (-not $IPv4 -and -not $IPv6) {
  $uri += "&clear=true"
}
$response = Invoke-WebRequest $uri
if ($Verbose) {
  Write-Output "$(Get-ISODate) - START"
  Write-Output "REQUEST"
  Write-Output $response.BaseResponse.RequestMessage.ToString()
  Write-Output "RESPONSE"
  Write-Output $response.RawContent
  Write-Output "$(Get-ISODate) - END"
}
else {
  Write-Output "$(Get-ISODate) - $(($response.RawContent -split "`r?`n")[-1]) - $uri"
}
