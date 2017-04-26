$NetAdapter = Get-NetAdapter | Where-Object {$_.NdisVersion -ge 6} | Select-Object -First 1
$TestDisableLsoIPv6 = [PSObject]@{
    Name     = $NetAdapter.Name
    Protocol = 'IPv6'
    State    = $true
}

configuration MSFT_xNetAdapterLso_Config {
    Import-DscResource -ModuleName xNetworking
    node localhost {
        xNetAdapterLso Integration_Test {
            Name        = $TestDisableLsoIPv6.Name
            Protocol    = $TestDisableLsoIPv6.Protocol
            State       = $TestDisableLsoIPv6.State
        }
    }
}
