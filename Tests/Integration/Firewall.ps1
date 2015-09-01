Configuration Firewall {
    Import-DscResource -ModuleName xNetworking
    node localhost {
       xFirewall Integration_Test {
            Name = $firewall.Name
            DisplayGroup = $firewall.DisplayGroup
            Ensure = 'Present'
            Enabled = $firewall.Enabled
            Profile = ($firewall.Profile).toString()
            Description = $firewall.Description
            LocalPort = $firewall.LocalPort
            Protocol = $firewall.Protocol
            Direction = $firewall.Direction
            ApplicationPath = $firewall.ApplicationPath
        }
    }
}
