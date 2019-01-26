<#PSScriptInfo
.VERSION 1.0.0
.GUID 202cc0cc-ffe2-493a-b6f3-9b525942a07a
.AUTHOR Microsoft Corporation
.COMPANYNAME Microsoft Corporation
.COPYRIGHT
.TAGS DSCConfiguration
.LICENSEURI https://github.com/PowerShell/NetworkingDsc/blob/master/LICENSE
.PROJECTURI https://github.com/PowerShell/NetworkingDsc
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES First version.
.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core
#>

#Requires -module NetworkingDsc

<#
    .DESCRIPTION
    Configure a network firewall rule using all parameters.
    Note: This configuration sample uses all Firewall rule parameters.
    It is only used to show example usage and should not be created.
#>
Configuration Firewall_AddFirewallRule_AllParameters_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        Firewall AddFirewallRuleAllParameters
        {
            Name                  = 'NotePadFirewallRule'
            DisplayName           = 'Firewall Rule for Notepad.exe'
            Group                 = 'NotePad Firewall Rule Group'
            Ensure                = 'Present'
            Enabled               = 'True'
            Profile               = ('Domain', 'Private')
            Direction             = 'OutBound'
            RemotePort            = ('8080', '8081')
            LocalPort             = ('9080', '9081')
            Protocol              = 'TCP'
            Description           = 'Firewall Rule for Notepad.exe'
            Program               = 'c:\windows\system32\notepad.exe'
            Service               = 'WinRM'
            Authentication        = 'Required'
            Encryption            = 'Required'
            InterfaceAlias        = 'Ethernet'
            InterfaceType         = 'Wired'
            LocalAddress          = ('192.168.2.0-192.168.2.128','192.168.1.0/255.255.255.0','10.0.0.0/8')
            LocalUser             = 'O:LSD:(D;;CC;;;S-1-15-3-4)(A;;CC;;;S-1-5-21-3337988176-3917481366-464002247-1001)'
            Package               = 'S-1-15-2-3676279713-3632409675-756843784-3388909659-2454753834-4233625902-1413163418'
            Platform              = '6.1'
            RemoteAddress         = ('192.168.2.0-192.168.2.128','192.168.1.0/255.255.255.0','10.0.0.0/8')
            RemoteMachine         = 'O:LSD:(D;;CC;;;S-1-5-21-1915925333-479612515-2636650677-1621)(A;;CC;;;S-1-5-21-1915925333-479612515-2636650677-1620)'
            RemoteUser            = 'O:LSD:(D;;CC;;;S-1-15-3-4)(A;;CC;;;S-1-5-21-3337988176-3917481366-464002247-1001)'
            DynamicTransport      = 'ProximitySharing'
            EdgeTraversalPolicy   = 'Block'
            IcmpType              = ('51','52')
            LocalOnlyMapping      = $true
            LooseSourceMapping    = $true
            OverrideBlockRules    = $true
            Owner                 = 'S-1-5-21-3337988176-3917481366-464002247-500'
        }
    }
}
