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

$adapter = Get-CimInstance -ClassName Win32_NetworkAdapter -Filter 'NetEnabled = "True"' | Select-Object -First 1

$current = [NetBiosSetting]($adapter | Get-CimAssociatedInstance -ResultClassName Win32_NetworkAdapterConfiguration).TcpipNetbiosOptions

Configuration MSFT_xNetBIOS_Config {
    Import-DscResource -ModuleName xNetworking
    
    node localhost {
        xNetBIOS Integration_Test {
            InterfaceAlias = $adapter.NetConnectionID
            Setting = $current
            EnableLmhostLookup = $true
        }
    }
}