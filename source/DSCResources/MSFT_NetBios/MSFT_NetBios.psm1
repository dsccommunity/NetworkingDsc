$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Networking Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'NetworkingDsc.Common' `
            -ChildPath 'NetworkingDsc.Common.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_NetBios'

#region check NetBiosSetting enum loaded, if not load
try
{
    [void][System.Reflection.Assembly]::GetAssembly([NetBiosSetting])
}
catch
{
    Add-Type -TypeDefinition @'
    public enum NetBiosSetting
    {
       Default,
       Enable,
       Disable
    }
'@
}
#endregion

<#
.SYNOPSIS
    Returns the current state of the Net Bios on an interface.

.PARAMETER InterfaceAlias
    Specifies the alias of a network interface. Supports the use of '*' and '%'.

.PARAMETER Setting
    Specifies if NetBIOS should be enabled or disabled or obtained from
    the DHCP server (Default). If static IP, Enable NetBIOS.

    Parameter value is ignored.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Default", "Enable", "Disable")]
        [System.String]
        $Setting
    )

    Write-Verbose -Message ($script:localizedData.GettingNetBiosSettingMessage -f $InterfaceAlias)

    $win32NetworkAdapterFilter = Format-Win32NetworkADapterFilterByNetConnectionID -InterfaceAlias $InterfaceAlias

    $netAdapter = Get-CimInstance `
        -ClassName Win32_NetworkAdapter `
        -Filter $win32NetworkAdapterFilter

    if ($netAdapter)
    {
        Write-Verbose -Message ($script:localizedData.InterfaceDetectedMessage -f $InterfaceAlias, $netAdapter.InterfaceIndex)
    }
    else
    {
        New-InvalidOperationException `
            -Message ($script:localizedData.InterfaceNotFoundError -f $InterfaceAlias)
    }

    $netAdapterConfig = $netAdapter | Get-CimAssociatedInstance `
        -ResultClassName Win32_NetworkAdapterConfiguration `
        -ErrorAction Stop

    $tcpipNetbiosOptions = $netAdapterConfig.TcpipNetbiosOptions

    if ($tcpipNetbiosOptions)
    {
        $Setting = $([NetBiosSetting].GetEnumValues()[$tcpipNetbiosOptions])
    }
    else
    {
        $Setting = 'Default'
    }

    Write-Verbose -Message ($script:localizedData.CurrentNetBiosSettingMessage -f $Setting)

    return @{
        InterfaceAlias = $InterfaceAlias
        Setting        = $Setting
    }
}

<#
.SYNOPSIS
    Sets the state of the Net Bios on an interface.

.PARAMETER InterfaceAlias
    Specifies the alias of a network interface. Supports the use of '*' and '%'.

.PARAMETER Setting
    Specifies if NetBIOS should be enabled or disabled or obtained from
    the DHCP server (Default). If static IP, Enable NetBIOS.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Default", "Enable", "Disable")]
        [System.String]
        $Setting
    )

    Write-Verbose -Message ($script:localizedData.SettingNetBiosSettingMessage -f $InterfaceAlias)

    $win32NetworkAdapterFilter = Format-Win32NetworkADapterFilterByNetConnectionID -InterfaceAlias $InterfaceAlias

    $netAdapter = Get-CimInstance `
        -ClassName Win32_NetworkAdapter `
        -Filter $win32NetworkAdapterFilter

    if ($netAdapter)
    {
        Write-Verbose -Message ($script:localizedData.InterfaceDetectedMessage -f $InterfaceAlias, $netAdapter.InterfaceIndex)
    }
    else
    {
        New-InvalidOperationException `
            -Message ($script:localizedData.InterfaceNotFoundError -f $InterfaceAlias)
    }

    $netAdapterConfig = $netAdapter | Get-CimAssociatedInstance `
        -ResultClassName Win32_NetworkAdapterConfiguration `
        -ErrorAction Stop

    if ($Setting -eq [NetBiosSetting]::Default)
    {
        Write-Verbose -Message $script:localizedData.ResetToDefaultMessage

        # If DHCP is not enabled, SetTcpipNetbios CIM Method won't take 0 so overwrite registry entry instead.
        $setItemPropertyParameters = @{
            Path  = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_$($NetAdapterConfig.SettingID)"
            Name  = 'NetbiosOptions'
            Value = 0
        }
        $null = Set-ItemProperty @setItemPropertyParameters
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.SetNetBiosMessage -f $Setting)

        $result = $netAdapterConfig |
            Invoke-CimMethod `
                -MethodName SetTcpipNetbios `
                -ErrorAction Stop `
                -Arguments @{
                    TcpipNetbiosOptions = [uint32][NetBiosSetting]::$Setting.value__
                }

        if ($result.ReturnValue -ne 0)
        {
            New-InvalidOperationException `
                -Message ($script:localizedData.FailedUpdatingNetBiosError -f $result.ReturnValue, $Setting)
        }
    }
}

<#
.SYNOPSIS
    Tests the current state the Net Bios on an interface.

.PARAMETER InterfaceAlias
    Specifies the alias of a network interface. Supports the use of '*' and '%'.

.PARAMETER Setting
    Specifies if NetBIOS should be enabled or disabled or obtained from
    the DHCP server (Default). If static IP, Enable NetBIOS.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Default", "Enable", "Disable")]
        [System.String]
        $Setting
    )

    Write-Verbose -Message ($script:localizedData.TestingNetBiosSettingMessage -f $InterfaceAlias)

    $win32NetworkAdapterFilter = Format-Win32NetworkADapterFilterByNetConnectionID -InterfaceAlias $InterfaceAlias

    $netAdapter = Get-CimInstance `
        -ClassName Win32_NetworkAdapter `
        -Filter $win32NetworkAdapterFilter

    if ($netAdapter)
    {
        Write-Verbose -Message ($script:localizedData.InterfaceDetectedMessage -f $InterfaceAlias, $netAdapter.InterfaceIndex)
    }
    else
    {
        New-InvalidOperationException `
            -Message ($script:localizedData.InterfaceNotFoundError -f $InterfaceAlias)
    }

    $currentState = Get-TargetResource @PSBoundParameters

    return Test-DscParameterState -CurrentValues $currentState -DesiredValues $PSBoundParameters
}

Export-ModuleMember -Function *-TargetResource
