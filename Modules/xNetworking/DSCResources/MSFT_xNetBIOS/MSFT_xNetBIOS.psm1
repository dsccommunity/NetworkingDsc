$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Networking Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'NetworkingDsc.Common' `
                                                     -ChildPath 'NetworkingDsc.Common.psm1'))

# Import the Networking Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'NetworkingDsc.ResourceHelper' `
                                                     -ChildPath 'NetworkingDsc.ResourceHelper.psm1'))

# Import Localization Strings
$localizedData = Get-LocalizedData `
-ResourceName 'MSFT_xNetBIOS' `
-ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

# region check NetBIOSSetting enum loaded, if not load
try
{
    [void][Reflection.Assembly]::GetAssembly([NetBiosSetting])
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
    Specifies the alias of a network interface. Supports the use of '*'.

    .PARAMETER Setting
    Default - Use NetBios settings from the DHCP server. If static IP, Enable NetBIOS.

    .PARAMETER EnableLmhostsLookup
    Indicates wheather the LMHosts lookup is enabled or disabled
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Default','Enable','Disable')]
        [string]
        $Setting,

        [Parameter()]
        [bool]
        $EnableLmhostsLookup
    )
                
    $filter = 'NetConnectionID="{0}"' -f $InterfaceAlias
    
    $nic = Get-CimInstance -ClassName Win32_NetworkAdapter -Filter $filter
    if ($nic)
    {
        Write-Verbose -Message ($localizedData.InterfaceDetected -f $InterfaceAlias, $nic.InterfaceIndex)
    }
    else
    {
        $errorParam = @{
            ErrorId = 'NicNotFound'
            ErrorMessage = ($localizedData.NicNotFound -f $InterfaceAlias)
            ErrorCategory = 'ObjectNotFound'
            ErrorAction = 'Stop'
        }
        New-TerminatingError @errorParam
    }

    $nicConfig = $nic | Get-CimAssociatedInstance -ResultClassName Win32_NetworkAdapterConfiguration
    
    return @{
        InterfaceAlias = $InterfaceAlias
        Setting = [string][NetBiosSetting]$nicConfig.TcpipNetbiosOptions
        EnableLmhostsLookup = $nicConfig.WINSEnableLMHostsLookup
    }
}

<#
    .SYNOPSIS
    Sets the state of the Net Bios on an interface.

    .PARAMETER InterfaceAlias
    Specifies the alias of a network interface. Supports the use of '*'.

    .PARAMETER Setting
    Default - Use NetBios settings from the DHCP server. If static IP, Enable NetBIOS.

    .PARAMETER EnableLmhostsLookup
    Enables or disables the LMHosts lookup
#>

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Default','Enable','Disable')]
        [string]
        $Setting,

        [Parameter()]
        [bool]
        $EnableLmhostsLookup
    )

    $filter = 'NetConnectionID="{0}"' -f $InterfaceAlias
    
    $nic = Get-CimInstance -ClassName Win32_NetworkAdapter -Filter $filter
    if ($nic)
    {
        Write-Verbose -Message ($localizedData.InterfaceDetected -f $InterfaceAlias, $nic.InterfaceIndex)
    }
    else
    {
        $errorParam = @{
            ErrorId = 'NicNotFound'
            ErrorMessage = ($localizedData.NicNotFound -f $InterfaceAlias)
            ErrorCategory = 'ObjectNotFound'
            ErrorAction = 'Stop'
        }
        New-TerminatingError @errorParam
    }

    $nicConfig = $nic | Get-CimAssociatedInstance -ResultClassName Win32_NetworkAdapterConfiguration

    # The setting can be changed with Win32_NetworkAdapterConfiguration.SetTcpipNetbios, but not if DHCP is disabled. Hence setting this via regsitry instead.
    Write-Verbose -Message ($localizedData.SetNetBIOS -f $Setting)
    $regParam = @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_$($nicConfig.SettingID)"
        Name = 'NetbiosOptions'
        Value = [uint32][NetBiosSetting]$Setting
    }
    $null = Set-ItemProperty @regParam

    if ($PSBoundParameters.ContainsKey('EnableLmhostsLookup'))
    {
        Write-Verbose -Message ($localizedData.SetLmhostLookup -f $EnableLmhostsLookup)
        
        Invoke-CimMethod -ClassName Win32_NetworkAdapterConfiguration -MethodName EnableWINS -Arguments @{ 
            DNSEnabledForWINSResolution = $nic.DNSEnabledForWINSResolution
            WINSEnableLMHostsLookup = $EnableLmhostsLookup
        }
    }
}

<#
    .SYNOPSIS
    Tests the current state the Net Bios on an interface.

    .PARAMETER InterfaceAlias
    Specifies the alias of a network interface. Supports the use of '*'.

    .PARAMETER Setting
    Default - Use NetBios settings from the DHCP server. If static IP, Enable NetBIOS.

    .PARAMETER EnableLmhostsLookup
    Enables or disables the LMHosts lookup
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([bool])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Default', 'Enable', 'Disable')]
        [string]
        $Setting,

        [Parameter()]
        [bool]
        $EnableLmhostsLookup
    )

    $currentState = Get-TargetResource @PSBoundParameters
    
    $result = Test-DscParameterState -CurrentValues $currentState -DesiredValues $PSBoundParameters
    
    return $result
}
