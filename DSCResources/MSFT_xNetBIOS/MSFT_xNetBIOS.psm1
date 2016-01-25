data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'

'@
}

try
{
    [void][reflection.assembly]::GetAssembly([NetBIOSSetting])
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

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $InterfaceAlias,

        [parameter(Mandatory = $true)]
        [ValidateSet("Default","Enable","Disable")]
        [System.String]
        $Setting
    )
    $Netadapterparams = @{
        ClassName = 'Win32_NetworkAdapter'
        Filter = 'NetConnectionID="{0}"' -f $InterfaceAlias
    }

    $NetAdapterConfig = Get-CimInstance @Netadapterparams -ErrorAction Stop |
            Get-CimAssociatedInstance `
                -ResultClassName Win32_NetworkAdapterConfiguration `
                -ErrorAction Stop

    return @{
        InterfaceAlias = $InterfaceAlias
        Setting = $([NETBIOSSetting].GetEnumValues()[$NetAdapterConfig.TcpipNetbiosOptions])
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $InterfaceAlias,

        [parameter(Mandatory = $true)]
        [ValidateSet("Default","Enable","Disable")]
        [System.String]
        $Setting
    )
    $Netadapterparams = @{
        ClassName = 'Win32_NetworkAdapter'
        Filter = 'NetConnectionID="{0}"' -f $InterfaceAlias
    }
    $NetAdapterConfig = Get-CimInstance @Netadapterparams -ErrorAction Stop |
            Get-CimAssociatedInstance `
                -ResultClassName Win32_NetworkAdapterConfiguration `
                -ErrorAction Stop

    if ($Setting -eq [NETBIOSSetting]::Default) 
    {
        #If DHCP is not enabled, settcpipnetbios CIM Method won't take 0 so overwrite registry entry instead.
        $RegParam = @{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_$($NetAdapterConfig.SettingID)"
            Name = 'NetbiosOptions'
            Value = 0
        }
        $null = Set-ItemProperty @RegParam
    }
    else
    {
        $null = $NetAdapterConfig | 
            Invoke-CimMethod -MethodName SetTcpipNetbios -ErrorAction Stop -Arguments @{
                TcpipNetbiosOptions = [uint32][NETBIOSSetting]::$Setting.value__
            }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $InterfaceAlias,

        [parameter(Mandatory = $true)]
        [ValidateSet("Default","Enable","Disable")]
        [System.String]
        $Setting
    )
    $NIC = Get-CimInstance `
        -ClassName Win32_NetworkAdapter `
        -Filter "NetConnectionID=`"$InterfaceAlias`""
    if ($Null -ne $NIC)
    {
        Write-Verbose -Message "Interface $InterfaceAlias detected with Index number: $($NIC.InterfaceIndex)"
    }
    else
    {
        throw "NIC with Alias $InterfaceAlias was not found"
    }

    $NICConfig = $NIC | Get-CimAssociatedInstance -ResultClassName Win32_NetworkAdapterConfiguration
    
    Write-Verbose -Message "Current Netbios Configuration: $([NETBIOSSetting].GetEnumValues()[$NICConfig.TcpipNetbiosOptions])"

    $DesiredSetting = ([NETBIOSSetting]::$($Setting)).value__
    Write-Verbose -Message "Desired Netbios Configuration: $Setting"

    if ($NICConfig.TcpipNetbiosOptions -eq $DesiredSetting) 
    {
        return $true
    }
    else 
    {
        return $false
    }
}


Export-ModuleMember -Function *-TargetResource

