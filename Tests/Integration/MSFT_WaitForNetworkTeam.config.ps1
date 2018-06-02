configuration MSFT_WaitForNetworkTeam_Config {
    Import-DscResource -ModuleName NetworkingDsc
    node localhost {
        WaitForNetworkTeam Integration_Test {
            Name             = $Node.Name
            RetryIntervalSec = $Node.RetryIntervalSec
            RetryCount       = $Node.RetryCount
        }
    }
}
