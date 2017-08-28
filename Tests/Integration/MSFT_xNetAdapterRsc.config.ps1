$NetAdapter = Get-NetAdapter | Where-Object {$_.NdisVersion -ge 6} | Select-Object -First 1
$TestEnableRscIPv6 = [PSObject]@{
    Name     = $NetAdapter.Name
    Protocol = 'IPv6'
    State    = $true
}

configuration MSFT_xNetAdapterRsc_Config {
    Import-DscResource -ModuleName xNetworking
    node localhost {
        xNetAdapterRsc Integration_Test {
            Name        = $TestEnableRscIPv6.Name
            Protocol    = $TestEnableRscIPv6.Protocol
            State       = $TestEnableRscIPv6.State
        }
    }
}