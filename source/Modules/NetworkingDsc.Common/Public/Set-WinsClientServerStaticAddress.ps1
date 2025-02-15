<#
    .SYNOPSIS
        Sets the WINS Client Server static address on a network adapter. The CIM class
        Win32_NetworkAdapterConfiguration unfortunately only supports the primary and
        secondary WINS server. The registry gives more flexibility.

    .PARAMETER InterfaceAlias
        Alias of the network interface to set the static WINS Server addresses on.
#>
function Set-WinsClientServerStaticAddress
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.String[]]
        $Address
    )

    Write-Verbose -Message ("$($MyInvocation.MyCommand): $($script:localizedData.SettingWinsServerStaticAddressMessage -f $InterfaceAlias, ($Address -join ', '))")

    # Look up the interface Guid
    $adapter = Get-NetAdapter `
        -InterfaceAlias $InterfaceAlias `
        -ErrorAction SilentlyContinue

    if (-not $adapter)
    {
        New-InvalidOperationException -Message ($script:localizedData.InterfaceAliasNotFoundError -f $InterfaceAlias)
    }

    $interfaceGuid = $adapter.InterfaceGuid.ToLower()

    $interfaceRegKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_$interfaceGuid\"

    Set-ItemProperty -Path $interfaceRegKeyPath -Name NameServerList -Value $Address

}
