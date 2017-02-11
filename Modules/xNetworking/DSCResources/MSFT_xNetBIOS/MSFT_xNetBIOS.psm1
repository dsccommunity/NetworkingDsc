$script:ResourceRootPath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent)

# Import the xNetworking Resource Module (to import the common modules)
Import-Module -Name (Join-Path -Path $script:ResourceRootPath -ChildPath 'xNetworking.psd1')

# Import Localization Strings
$localizedData = Get-LocalizedData `
    -ResourceName 'MSFT_xNetBIOS' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

#region check NetBIOSSetting enum loaded, if not load
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

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory)]
        [string]$InterfaceAlias,

        [Parameter(Mandatory)]
        [ValidateSet('Default','Enable','Disable')]
        [string]$Setting,

        [Parameter(Mandatory)]
        [bool]$EnableLmhostLookup
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
        Setting = [NetBiosSetting]$nicConfig.TcpipNetbiosOptions
        EnableLmhostLookup = $nicConfig.WINSEnableLMHostsLookup
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]$InterfaceAlias,

        [Parameter(Mandatory)]
        [ValidateSet('Default','Enable','Disable')]
        [string]$Setting,

        [Parameter(Mandatory)]
        [bool]$EnableLmhostLookup
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

    if ($Setting -eq [NetBiosSetting]::Default)
    {
        Write-Verbose -Message $localizedData.ResetToDefaut
        #If DHCP is not enabled, Win32_NetworkAdapterConfiguration.SetTcpipNetbios CIM Method won't take 0 so overwrite registry entry instead.
        $regParam = @{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_$($nicConfig.SettingID)"
            Name = 'NetbiosOptions'
            Value = 0
        }
        $null = Set-ItemProperty @regParam
    }
    else
    {
        Write-Verbose -Message ($localizedData.SetNetBIOS -f $Setting)
        $null = $nicConfig | 
        Invoke-CimMethod -MethodName SetTcpipNetbios -ErrorAction Stop -Arguments @{
            TcpipNetbiosOptions = [uint32][NetBiosSetting]$Setting
        }
    }

    if ($PSBoundParameters.ContainsKey('EnableLmhostLookup'))
    {
        $networkAdapterConfigClass = [wmiclass]'Win32_NetworkAdapterConfiguration'
        if ($EnableLmhostLookup -ne $nicConfig.WINSEnableLMHostsLookup)
        {
            $networkAdapterConfigClass.EnableWINS($networkAdapterConfigClass.DNSEnabledForWINSResolution, $EnableLmhostLookup)
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [Parameter(Mandatory)]
        [string]$InterfaceAlias,

        [Parameter(Mandatory)]
        [ValidateSet('Default','Enable','Disable')]
        [string]$Setting,

        [Parameter(Mandatory)]
        [bool]$EnableLmhostLookup
    )

    $currentState = Get-TargetResource @PSBoundParameters
    
    $result = Test-DscParameterState -CurrentValues $currentState -DesiredValues $PSBoundParameters -Verbose:$VerbosePreference #-ValuesToCheck -ValuesToCheck ([array]@("Ensure"))
    
    return $result
}

Export-ModuleMember -Function *-TargetResource