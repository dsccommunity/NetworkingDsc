<#
  This file exists so we can load the test file without necessarily having NetworkingDsc in
  the $env:PSModulePath. Otherwise PowerShell will throw an error when reading the Pester File
#>
Configuration MSFT_Firewall_Add_Config {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
       Firewall Integration_Test {
            Name                  = $Node.RuleName
            DisplayName           = $Node.DisplayName
            Group                 = $Node.Group
            Ensure                = $Node.Ensure
            Enabled               = $Node.Enabled
            Profile               = $Node.Profile
            Action                = $Node.Action
            Description           = $Node.Description
            Direction             = $Node.Direction
            RemotePort            = $Node.RemotePort
            LocalPort             = $Node.LocalPort
            Protocol              = $Node.Protocol
            Program               = $Node.Program
            Service               = $Node.Service
            Authentication        = $Node.Authentication
            Encryption            = $Node.Encryption
            InterfaceAlias        = $Node.InterfaceAlias
            InterfaceType         = $Node.InterfaceType
            LocalAddress          = $Node.LocalAddress
            LocalUser             = $Node.LocalUser
            Package               = $Node.Package
            Platform              = $Node.Platform
            RemoteAddress         = $Node.RemoteAddress
            RemoteMachine         = $Node.RemoteMachine
            RemoteUser            = $Node.RemoteUser
            DynamicTransport      = $Node.DynamicTransport
            EdgeTraversalPolicy   = $Node.EdgeTraversalPolicy
            LocalOnlyMapping      = $Node.LocalOnlyMapping
            LooseSourceMapping    = $Node.LooseSourceMapping
            OverrideBlockRules    = $Node.OverrideBlockRules
            Owner                 = $Node.Owner
            IcmpType              = $Node.IcmpType
        }
    }
}
