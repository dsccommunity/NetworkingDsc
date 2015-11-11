<#
  This file exists so we can load the test file without necessarily having xNetworking in
  the $env:PSModulePath. Otherwise PowerShell will throw an error when reading the Pester File
#>

$rule = @{
    Name                  = 'b8df0af9-d0cc-4080-885b-6ed263aaed67'
    DisplayName           = 'Test Rule'
    Group                 = 'Test Group'
    Ensure                = 'Present'
    Enabled               = 'False'
    Profile               = 'Domain, Private'
    Action                = 'Allow'
    Description           = 'MSFT_xFirewall Test Firewall Rule'
    Direction             = 'Inbound'
    RemotePort            = ('8080', '8081')
    LocalPort             = ('9080', '9081')
    Protocol              = 'TCP'
    Program               = 'c:\windows\system32\notepad.exe'
    Service               = 'WinRM'
    Authentication        = 'Required'
    Encryption            = 'Required'
    InterfaceAlias        = 'Ethernet'
    InterfaceType         = 'Wired'
    LocalAddress          = @('192.168.2.0-192.168.2.128','192.168.1.0/255.255.255.0')
    LocalUser             = 'O:LSD:(D;;CC;;;S-1-15-3-4)(A;;CC;;;S-1-5-21-3337988176-3917481366-464002247-1001)'
    Package               = 'S-1-15-2-3676279713-3632409675-756843784-3388909659-2454753834-4233625902-1413163418'
    Platform              = '6.1'
    RemoteAddress         = @('192.168.2.0-192.168.2.128','192.168.1.0/255.255.255.0')
    RemoteMachine         = 'O:LSD:(D;;CC;;;S-1-5-21-1915925333-479612515-2636650677-1621)(A;;CC;;;S-1-5-21-1915925333-479612515-2636650677-1620)'
    RemoteUser            = 'O:LSD:(D;;CC;;;S-1-15-3-4)(A;;CC;;;S-1-5-21-3337988176-3917481366-464002247-1001)'
}

Configuration Firewall {
    Import-DscResource -ModuleName xNetworking
    node localhost {
       xFirewall Integration_Test {
            Name                  = $rule.Name
            DisplayName           = $rule.DisplayName
            Group                 = $rule.Group
            Ensure                = 'Present'
            Enabled               = $rule.Enabled
            Profile               = ($rule.Profile).toString()
            Action                = $rule.Action
            Description           = $rule.Description
            Direction             = $rule.Direction
            RemotePort            = $rule.RemotePort
            LocalPort             = $rule.LocalPort
            Protocol              = $rule.Protocol
            Program               = $rule.Program
            Service               = $rule.Service
            Authentication        = $rule.Authentication
            Encryption            = $rule.Encryption
            InterfaceAlias        = $rule.InterfaceAlias
            InterfaceType         = $rule.InterfaceType
            LocalAddress          = $rule.LocalAddress
            LocalUser             = $rule.LocalUser
            Package               = $rule.Package
            Platform              = $rule.Platform
            RemoteAddress         = $rule.RemoteAddress
            RemoteMachine         = $rule.RemoteMachine
            RemoteUser            = $rule.RemoteUser
        }
    }
}
