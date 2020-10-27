$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Networking Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'NetworkingDsc.Common' `
            -ChildPath 'NetworkingDsc.Common.psm1'))

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

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
    if( $netAdapter -is [Array] )
    {
        [string[]] $SettingResults = @()

        foreach ( $netAdapterItem in $netAdapter )
        {
            $SettingResults += Get-NetAdapterNetbiosOptionsFromRegistry -NetworkAdapterGUID $netAdapterItem.GUID -Setting $Setting

            Write-Verbose -Message ($script:localizedData.CurrentNetBiosSettingMessage -f $netAdapterItem.NetConnectionID,$SettingResults[-1])
        }

        [string[]] $WrongSettings = $SettingResults | Where-Object{ $_ -ne $Setting }

        if([System.String]::IsNullOrEmpty($WrongSettings) -eq $false)
        {
            [string] $Setting = $WrongSettings[0]
        }
    }
    else
    {
        $Setting = Get-NetAdapterNetbiosOptionsFromRegistry -NetworkAdapterGUID $netAdapter.GUID -Setting $Setting
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

    if( $netAdapter -is [Array] )
    {
        foreach( $netAdapterItem in $netAdapter )
        {
            $CurrentValue = Get-NetAdapterNetbiosOptionsFromRegistry -NetworkAdapterGUID $netAdapterItem.GUID -Setting $Setting

            # Only make changes if necessary
            if( $CurrentValue -ne $Setting )
            {
                Write-Verbose -Message ($script:localizedData.SetNetBiosMessage -f $netAdapterItem.NetConnectionID, $Setting)

                $netAdapterConfig = $netAdapterItem | Get-CimAssociatedInstance `
                    -ResultClassName Win32_NetworkAdapterConfiguration `
                    -ErrorAction Stop

                Set-NetAdapterNetbiosOptions -NetworkAdapterObj $netAdapterConfig `
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

        Set-NetAdapterNetbiosOptions -NetworkAdapterObj $netAdapterConfig `
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

Export-ModuleMember -Function *-TargetResource
