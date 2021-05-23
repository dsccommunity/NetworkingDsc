$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Networking Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'NetworkingDsc.Common' `
            -ChildPath 'NetworkingDsc.Common.psm1'))

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

# Base registry key path for NetBios settings
$script:hklmInterfacesPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces'

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
        [ValidateSet('Default', 'Enable', 'Disable')]
        [System.String]
        $Setting
    )

    Write-Verbose -Message ($script:localizedData.GettingNetBiosSettingMessage -f $InterfaceAlias)

    $win32NetworkAdapterFilter = Format-Win32NetworkAdapterFilterByNetConnectionId -InterfaceAlias $InterfaceAlias

    $netAdapter = Get-CimInstance `
        -ClassName Win32_NetworkAdapter `
        -Filter $win32NetworkAdapterFilter

    if ($netAdapter)
    {
        Write-Verbose -Message ($script:localizedData.InterfaceDetectedMessage -f $InterfaceAlias, ($netAdapter.InterfaceIndex -Join ','))
    }
    else
    {
        New-InvalidOperationException `
            -Message ($script:localizedData.InterfaceNotFoundError -f $InterfaceAlias)
    }

    <#
        If a wildcard was specified for the InterfaceAlias then
        more than one adapter may be returned. If more than one
        adapter is returned then the NetBios setting value will
        be evaluated for all matching adapters. If there is a
        mismatch, a wrong value is returned to signify the
        resource is not in the desired state.
    #>
    if ($netAdapter -is [System.Array])
    {
        [System.String[]] $settingResults = @()

        foreach ($netAdapterItem in $netAdapter)
        {
            $settingResults += Get-NetAdapterNetbiosOptionsFromRegistry `
                -NetworkAdapterGUID $netAdapterItem.GUID `
                -Setting $Setting

            Write-Verbose -Message ($script:localizedData.CurrentNetBiosSettingMessage -f $netAdapterItem.NetConnectionID, $settingResults[-1])
        }

        [System.String[]] $wrongSettings = $settingResults | Where-Object -FilterScript {
            $_ -ne $Setting
        }

        if (-not [System.String]::IsNullOrEmpty($wrongSettings))
        {
            $Setting = $wrongSettings[0]
        }
    }
    else
    {
        $Setting = Get-NetAdapterNetbiosOptionsFromRegistry `
            -NetworkAdapterGUID $netAdapter.GUID `
            -Setting $Setting
    }

    Write-Verbose -Message ($script:localizedData.CurrentNetBiosSettingMessage -f $InterfaceAlias, $Setting)

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
        [ValidateSet('Default', 'Enable', 'Disable')]
        [System.String]
        $Setting
    )

    Write-Verbose -Message ($script:localizedData.SettingNetBiosSettingMessage -f $InterfaceAlias)

    $win32NetworkAdapterFilter = Format-Win32NetworkAdapterFilterByNetConnectionId -InterfaceAlias $InterfaceAlias

    $netAdapter = Get-CimInstance `
        -ClassName Win32_NetworkAdapter `
        -Filter $win32NetworkAdapterFilter

    if ($netAdapter)
    {
        Write-Verbose -Message ($script:localizedData.InterfaceDetectedMessage -f $InterfaceAlias, ($netAdapter.InterfaceIndex -Join ','))
    }
    else
    {
        New-InvalidOperationException `
            -Message ($script:localizedData.InterfaceNotFoundError -f $InterfaceAlias)
    }

    if ($netAdapter -is [System.Array])
    {
        foreach ($netAdapterItem in $netAdapter)
        {
            $currentValue = Get-NetAdapterNetbiosOptionsFromRegistry `
                -NetworkAdapterGUID $netAdapterItem.GUID `
                -Setting $Setting

            # Only make changes if necessary
            if ($currentValue -ne $Setting)
            {
                Write-Verbose -Message ($script:localizedData.SetNetBiosMessage -f $netAdapterItem.NetConnectionID, $Setting)

                $netAdapterConfig = $netAdapterItem | Get-CimAssociatedInstance `
                    -ResultClassName Win32_NetworkAdapterConfiguration `
                    -ErrorAction Stop

                Set-NetAdapterNetbiosOptions `
                    -NetworkAdapterObject $netAdapterConfig `
                    -InterfaceAlias $netAdapterItem.NetConnectionID `
                    -Setting $Setting
            }
        }
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.SetNetBiosMessage -f $netAdapter.NetConnectionID, $Setting)

        $netAdapterConfig = $netAdapter | Get-CimAssociatedInstance `
                    -ResultClassName Win32_NetworkAdapterConfiguration `
                    -ErrorAction Stop

        Set-NetAdapterNetbiosOptions `
            -NetworkAdapterObject $netAdapterConfig `
            -InterfaceAlias $netAdapter.NetConnectionID `
            -Setting $Setting
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
        [ValidateSet('Default', 'Enable', 'Disable')]
        [System.String]
        $Setting
    )

    Write-Verbose -Message ($script:localizedData.TestingNetBiosSettingMessage -f $InterfaceAlias)

    $currentState = Get-TargetResource @PSBoundParameters

    return Test-DscParameterState -CurrentValues $currentState -DesiredValues $PSBoundParameters
}

<#
    .SYNOPSIS
        Returns the NetbiosOptions value for a network adapter.

    .DESCRIPTION
        Most reliable method of getting this value since network adapters
        can be in any number of states (e.g. disabled, disconnected)
        which can cause Win32 classes to not report the value.

    .PARAMETER NetworkAdapterGUID
        Network Adapter GUID

    .PARAMETER Setting
        Setting value for this resource which should be one of
        the following: Default, Enable, Disable
#>
function Get-NetAdapterNetbiosOptionsFromRegistry
{
    [OutputType([System.String])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidatePattern("^\{[a-zA-Z0-9]{8}\-[a-zA-Z0-9]{4}\-[a-zA-Z0-9]{4}\-[a-zA-Z0-9]{4}\-[a-zA-Z0-9]{12}\}$")]
        [System.String]
        $NetworkAdapterGUID,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Default','Enable','Disable')]
        [System.String]
        $Setting
    )

    # Changing ErrorActionPreference variable since the switch -ErrorAction isn't supported.
    $currentErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'

    $registryNetbiosOptions = Get-ItemPropertyValue `
        -Name 'NetbiosOptions' `
        -Path "$($script:hklmInterfacesPath)\Tcpip_$($NetworkAdapterGUID)"

    $ErrorActionPreference = $currentErrorActionPreference

    if ($null -eq $registryNetbiosOptions)
    {
        $registryNetbiosOptions = 0
    }

    switch ($registryNetbiosOptions)
    {
        0
        {
            return 'Default'
        }

        1
        {
            return 'Enable'
        }

        2
        {
            return 'Disable'
        }

        default
        {
            # Unknown value. Returning invalid setting to trigger Set-TargetResource
            [System.String[]] $invalidSetting = 'Default','Enable','Disable' | Where-Object -FilterScript {
                $_ -ne $Setting
            }

            return $invalidSetting[0]
        }
    }
} # end function Get-NetAdapterNetbiosOptionsFromRegistry

<#
    .SYNOPSIS
        Configures Netbios on a Network Adapter.

    .DESCRIPTION
        Uses two methods for configuring Netbios on a Network Adapter.
        If an interface is IPEnabled, the CIMMethod will be invoked.
        Otherwise the registry key is configured as this will satisfy
        network adapters being in alternative states such as disabled
        or disconnected.

    .PARAMETER NetworkAdapterObject
        Network Adapter Win32_NetworkAdapterConfiguration Object

    .PARAMETER InterfaceAlias
        Name of the network adapter being configured. Example: Ethernet

    .PARAMETER Setting
        Setting value for this resource which should be one of
        the following: Default, Enable, Disable
#>
function Set-NetAdapterNetbiosOptions
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $NetworkAdapterObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Default','Enable','Disable')]
        [System.String]
        $Setting
    )

    Write-Verbose -Message ($script:localizedData.SetNetBiosMessage -f $InterfaceAlias, $Setting)

    # Only IPEnabled interfaces can be configured via SetTcpipNetbios method.
    if ($NetworkAdapterObject.IPEnabled)
    {
        $result = $NetworkAdapterObject |
            Invoke-CimMethod `
                -MethodName SetTcpipNetbios `
                -ErrorAction Stop `
                -Arguments @{
                    TcpipNetbiosOptions = [uint32][NetBiosSetting]::$Setting.value__
                }

        if ($result.ReturnValue -ne 0)
        {
            New-InvalidOperationException `
                -Message ($script:localizedData.FailedUpdatingNetBiosError -f $InterfaceAlias, $result.ReturnValue, $Setting)
        }
    }
    else
    {
        <#
            IPEnabled=$false can only be configured via registry
            this satisfies disabled and disconnected states
        #>
        $setItemPropertyParameters = @{
            Path  = "$($script:hklmInterfacesPath)\Tcpip_$($NetworkAdapterObject.SettingID)"
            Name  = 'NetbiosOptions'
            Value = [NetBiosSetting]::$Setting.value__
        }
        $null = Set-ItemProperty @setItemPropertyParameters
    }
} # end function Set-NetAdapterNetbiosOptions

Export-ModuleMember -Function *-TargetResource
