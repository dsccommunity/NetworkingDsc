$NetAdapter = Get-NetAdapter -Name NetworkingDscLBA
$TestNetAdapterState = [PSObject]@{
    Name     = $NetAdapter.Name
    State    = 'Disabled'
}

configuration MSFT_NetAdapterState_Config {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        NetAdapterState Integration_Test
        {
            Name     = $TestNetAdapterState.Name
            State    = $TestNetAdapterState.State
        }
    }
}
