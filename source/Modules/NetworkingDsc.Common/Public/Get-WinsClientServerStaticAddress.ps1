<#
    .SYNOPSIS
        Returns the WINS Client Server static address that are assigned to a network
        adapter. The CIM class Win32_NetworkAdapterConfiguration unfortunately only supports
        the primary and secondary WINS server. The registry gives more flexibility.

    .PARAMETER InterfaceAlias
        Alias of the network interface to get the static WINS Server addresses from.
#>
function Get-WinsClientServerStaticAddress
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InterfaceAlias
    )

    Write-Verbose -Message ("$($MyInvocation.MyCommand): $($script:localizedData.GettingWinsServerStaticAddressMessage -f $InterfaceAlias)")

    # Look up the interface Guid
    $adapter = Get-NetAdapter `
        -InterfaceAlias $InterfaceAlias `
        -ErrorAction SilentlyContinue

    if (-not $adapter)
    {
        New-InvalidOperationException -Message ($script:localizedData.InterfaceAliasNotFoundError -f $InterfaceAlias)

        # Return null to support ErrorAction Silently Continue
        return $null
    }

    $interfaceGuid = $adapter.InterfaceGuid.ToLower()

    $interfaceRegKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_$interfaceGuid\"

    $interfaceInformation = Get-ItemProperty -Path $interfaceRegKeyPath -ErrorAction SilentlyContinue
    $nameServerAddressString = $interfaceInformation.NameServerList

    # Are any statically assigned addresses for this adapter?
    if (-not $nameServerAddressString)
    {
        # Static DNS Server addresses not found so return empty array
        Write-Verbose -Message ("$($MyInvocation.MyCommand): $($script:localizedData.WinsServerStaticAddressNotSetMessage -f $InterfaceAlias)")
        return $null
    }
    else
    {
        # Static DNS Server addresses found so split them into an array using comma
        Write-Verbose -Message ("$($MyInvocation.MyCommand): $($script:localizedData.WinsServerStaticAddressFoundMessage -f
        $InterfaceAlias, ($nameServerAddressString -join ','))")

        return $nameServerAddressString
    }
}
