<#
  This file exists so we can load the test file without necessarily having xNetworking in
  the $env:PSModulePath. Otherwise PowerShell will throw an error when reading the Pester File
#>
Configuration MSFT_xFirewall_Remove_Config {
    Import-DscResource -ModuleName xNetworking
    node localhost {
       xFirewall Integration_Test {
            Name                  = $Node.RuleName
            Ensure                = $Node.Ensure
        }
    }
}
