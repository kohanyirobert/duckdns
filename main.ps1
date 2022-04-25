#requires -Version 5.1

using namespace System.Collections.ObjectModel
using namespace System.Management.Automation

[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]
  $Domain,

  [Parameter(Mandatory)]
  [ValidateSet('IPv4', 'IPv6', 'Clear')]
  [string]
  $Operation,

  [TimeSpan]
  $RequestTimeout = '00:00:03'
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

  $uri = "https://www.duckdns.org/update?token=$Token&domains=$Domain"
  switch ($Operation) {
    Clear {
      $uri += "&clear=true"
    }
    IPv4 {
      $uri += "&ip="
    }
    IPv6 {
      $alias = Get-ActiveInterfaceAlias
      $ipv6 = Get-IPv6Address $alias
      $uri += "&ipv6=$ipv6"
    }
    default {
      throw "Unsupported operation: $Operation"
    }
  }
  if ($VerbosePreference) {
    $uri += "&verbose=true"
  }
  Write-Verbose "Uri: $uri"
  $response = Invoke-WebRequest -TimeoutSec $RequestTimeout.Seconds $uri
  Write-Verbose "Request: $($response.BaseResponse.RequestMessage)"
  Write-Verbose "Response: $($response.RawContent)"
  Write-Output "$(Get-Date) $(($response.RawContent -split "`r?`n")[-1])"
}
