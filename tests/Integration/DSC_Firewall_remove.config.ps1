<#
  This file exists so we can load the test file without necessarily having NetworkingDsc in
  the $env:PSModulePath. Otherwise PowerShell will throw an error when reading the Pester File
#>
Configuration DSC_Firewall_Remove_Config {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        Firewall Integration_Test
        {
            Name   = $Node.RuleName
            Ensure = $Node.Ensure
        }
    }
}
