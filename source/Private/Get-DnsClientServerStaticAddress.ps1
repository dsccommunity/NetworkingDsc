<#
    .SYNOPSIS
        Returns the DNS Client Server static address that are assigned to a network
        adapter. This is required because Get-DnsClientServerAddress always returns
        the currently assigned server addresses whether regardless if they were
        assigned as static or by DHCP.

        The only way that could be found to do this is to query the registry.

    .PARAMETER InterfaceAlias
        Alias of the network interface to get the static DNS Server addresses from.

    .PARAMETER AddressFamily
        IP address family.
#>
function Get-DnsClientServerStaticAddress
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [System.String]
        $AddressFamily
    )

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($script:localizedData.GettingDNSServerStaticAddressMessage) -f $AddressFamily, $InterfaceAlias
        ) -join '')

    # Look up the interface Guid
    $adapter = Get-NetAdapter `
        -InterfaceAlias $InterfaceAlias `
        -ErrorAction SilentlyContinue

    if (-not $adapter)
    {
        New-InvalidOperationException `
            -Message ($script:localizedData.InterfaceAliasNotFoundError `
                -f $InterfaceAlias)

        # Return null to support ErrorAction Silently Continue
        return $null
    } # if

    $interfaceGuid = $adapter.InterfaceGuid.ToLower()

    if ($AddressFamily -eq 'IPv4')
    {
        $interfaceRegKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$interfaceGuid\"
    }
    else
    {
        $interfaceRegKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\Interfaces\$interfaceGuid\"
    } # if

    $interfaceInformation = Get-ItemProperty `
        -Path $interfaceRegKeyPath `
        -ErrorAction SilentlyContinue
    $nameServerAddressString = $interfaceInformation.NameServer

    # Are any statically assigned addresses for this adapter?
    if ([System.String]::IsNullOrWhiteSpace($nameServerAddressString))
    {
        # Static DNS Server addresses not found so return empty array
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                $($script:localizedData.DNSServerStaticAddressNotSetMessage) -f $AddressFamily, $InterfaceAlias
            ) -join '')

        return @()
    }
    else
    {
        # Static DNS Server addresses found so split them into an array using comma
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                $($script:localizedData.DNSServerStaticAddressFoundMessage) -f $AddressFamily, $InterfaceAlias, $nameServerAddressString
            ) -join '')

        return @($nameServerAddressString -split ',')
    } # if
}
