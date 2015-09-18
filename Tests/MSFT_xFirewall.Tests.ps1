$here = Split-Path -Parent $MyInvocation.MyCommand.Path

if (Get-Module MSFT_xFirewall -All)
{
    Get-Module MSFT_xFirewall -All | Remove-Module
}

Import-Module -Name $PSScriptRoot\..\DSCResources\MSFT_xFirewall -Force -DisableNameChecking

InModuleScope MSFT_xFirewall {

    Describe 'Get-TargetResource' {
        # Get a firewall rule that will be used to test with - any will do
        $FirewallRule = Get-NetFirewallRule | Select-Object -First 1

        Context 'testing with an existing firewall rule' {
            It 'should return Ensure Present with Object properties' {
                $Result = Get-TargetResource -Name $FirewallRule.Name -Access $FirewallRule.Action
                $Result.Ensure | Should Be 'Present'
                $Result.DisplayName = $firewallRule.DisplayName
                $Result.DisplayGroup = $firewallRule.DisplayGroup
                $Result.Access = $firewallRule.Action
                $Result.State = $firewallRule.State
                $Result.Profile = $firewallRule.Profile.ToString() -replace(" ", "") -split(",")
                $Result.Direction = $firewallRule.Direction
            }
        }
        Context 'testing with a non-existent firewall rule' {
            It 'should return Ensure Absent' {
                $Result = Get-TargetResource -Name 'Not a Real Rule' -Access $FirewallRule.Action
                $Result.Ensure | Should Be 'Absent'
            }
        }
    }

    Describe 'Set-TargetResource' {
        $TestRule = @{
            Name = 'Test Rule'
            DisplayName = 'Test Display Name'
            DisplayGroup = 'Test Group'
            Ensure = 'Present'
            State = 'Enabled'
            Profile = 'Private'
            Direction = 'Inbound'
            Access = 'Block'
            RemotePort = 1234
            LocalPort = 5678
            Protocol = 'TCP'
            Description = 'Test Description'
            ApplicationPath = 'Test Program'
            Service = 'Test Service'
        }

        Context 'testing with a rule that already exists' {
            It 'should return Ensure Present with Object properties' {
            }
        }
        
    }

    Describe 'Test-TargetResource' {
    }

    Describe 'Set-FirewallRule' {
        $TestRule = @{
            Name = 'Test Rule'
            DisplayName = 'Test Display Name'
            DisplayGroup = 'Test Group'
            State = 'Enabled'
            Profile = 'Private'
            Direction = 'Inbound'
            Access = 'Block'
            RemotePort = 1234
            LocalPort = 5678
            Protocol = 'TCP'
            Description = 'Test Description'
            ApplicationPath = 'Test Program'
            Service = 'Test Service'
        }
        $TestRule.Values
        Mock New-NetFirewallRule -MOckWith { Return $TestRule }

        Context 'testing with all properties provided' {
            It 'should return object with expected properties' {
                $Result = Set-FirewallRule @TestRule
                @(Compare-Object -ReferenceObject $Result -DifferenceObject $TestRule).Count | Should Be 0
            }
            It 'should call New-NetFirewallRule once' {
                Assert-MockCalled -commandName New-NetFirewallRule -Exactly 1
            }
        }
    }

    Describe 'Test-RuleHasProperties' {
        # Get a firewall rule that will be used to test with - any will do
        $FirewallRule = Get-FirewallRules -Name ((Get-NetFirewallRule | Select-Object -First 1).Name)
        $Properties = Get-FirewallRuleProperty -FirewallRule $FirewallRule -Property All
        # To speed up all these tests create Mocks so that these functions are not repeatedly called
        Mock Get-FirewallRules -MockWith { $FirewallRule }
        Mock Get-FirewallRuleProperty -MockWith { $Properties }

        # Make an object that can be splatted onto the function
        $Splat = @{
            Name = $FirewallRule.Name
            DisplayGroup = $FirewallRule.DisplayGroup
            State = if ($FirewallRule.Enabled.ToString() -eq 'True') { 'Enabled' } else { 'Disabled' }
            Profile = $FirewallRule.Profile.ToString() -replace(" ", "") -split(",")
            Direction = $FirewallRule.Direction
            Access = $FirewallRule.Action
            RemotePort = $Properties.PortFilters.RemotePort
            LocalPort = $Properties.PortFilters.LocalPort
            Protocol = $Properties.PortFilters.Protocol
            Description = $FirewallRule.Description
            ApplicationPath = $FirewallRule.ApplicationFilters.Program
            Service = $FirewallRule.ServiceFilters.Service
        }
        Context 'testing with a rule with no property differences' {
            $CompareRule = $Splat.Clone()
            It 'should return True' {
                $Result = Test-RuleHasProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $True
            }
        }
        Context 'testing with a rule with a different name' {
            $CompareRule = $Splat.Clone()
            $CompareRule.Name = 'Different'
            It 'should return False' {
                $Result = Test-RuleHasProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different state' {
            $CompareRule = $Splat.Clone()
            $CompareRule.State = if ($CompareRule.State -eq 'Enabled') { 'Disabled' } else { 'Enabled' }
            It 'should return False' {
                $Result = Test-RuleHasProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different profile' {
            $CompareRule = $Splat.Clone()
            $CompareRule.Profile = 'Different'
            It 'should return False' {
                $Result = Test-RuleHasProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different direction' {
            $CompareRule = $Splat.Clone()
            $CompareRule.Direction = 'Different'
            It 'should return False' {
                $Result = Test-RuleHasProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different remote port' {
            $CompareRule = $Splat.Clone()
            $CompareRule.RemotePort = 1
            It 'should return False' {
                $Result = Test-RuleHasProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different local port' {
            $CompareRule = $Splat.Clone()
            $CompareRule.LocalPort = 1
            It 'should return False' {
                $Result = Test-RuleHasProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different protocol' {
            $CompareRule = $Splat.Clone()
            $CompareRule.Protocol = "Different"
            It 'should return False' {
                $Result = Test-RuleHasProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different description' {
            $CompareRule = $Splat.Clone()
            $CompareRule.Description = "Different"
            It 'should return False' {
                $Result = Test-RuleHasProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different application path' {
            $CompareRule = $Splat.Clone()
            $CompareRule.ApplicationPath = "Different"
            It 'should return False' {
                $Result = Test-RuleHasProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different description' {
            $CompareRule = $Splat.Clone()
            $CompareRule.Service = "Different"
            It 'should return False' {
                $Result = Test-RuleHasProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
    }

    Describe ' Get-FirewallRules' {
        # Get a firewall rule that will be used to test with - any will do
        $FirewallRule = Get-NetFirewallRule | Select-Object -First 1

        Context 'testing with firewall that exists' {
            It 'should return a firewall rule when name is passed' {
                $Result = Get-FirewallRules -Name $FirewallRule.Name
                $Result | Should Not BeNullOrEmpty
            }
            It 'should return a firewall rule when name and display group is passed' {
                $Result = Get-FirewallRules -Name $FirewallRule.Name -DisplayGroup $FirewallRule.Group
                $Result | Should Not BeNullOrEmpty
            }
        }
        Context 'testing with firewall that does not exist' {
            It 'should not return anything' {
                $Result = Get-FirewallRules -Name 'Does not exist'
                $Result | Should BeNullOrEmpty
            }
        }
    }

    Describe ' Get-FirewallRuleProperty' {

        # Get a firewall rule that will be used to test with - any will do
        $FirewallRule = Get-NetFirewallRule | Select-Object -First 1

        Context 'testing with all properties requested' {
            It 'should return all properties' {
                $Result = Get-FirewallRuleProperty -FirewallRule $FirewallRule -Property All
                @(Compare-Object -ReferenceObject $Result.AddressFilters -DifferenceObject (Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $FirewallRule)).Count | Should Be 0
                @(Compare-Object -ReferenceObject $Result.ApplicationFilters -DifferenceObject (Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $FirewallRule)).Count | Should Be 0
                @(Compare-Object -ReferenceObject $Result.InterfaceFilters -DifferenceObject (Get-NetFirewallInterfaceFilter -AssociatedNetFirewallRule $FirewallRule)).Count | Should Be 0
                @(Compare-Object -ReferenceObject $Result.InterfaceTypeFilters -DifferenceObject (Get-NetFirewallInterfaceTypeFilter -AssociatedNetFirewallRule $FirewallRule)).Count | Should Be 0
                @(Compare-Object -ReferenceObject $Result.PortFilters -DifferenceObject (Get-NetFirewallPortFilter -AssociatedNetFirewallRule $FirewallRule)).Count | Should Be 0
                @(Compare-Object -ReferenceObject $Result.Profile -DifferenceObject (Get-NetFirewallProfile -AssociatedNetFirewallRule $FirewallRule)).Count | Should Be 0
                @(Compare-Object -ReferenceObject $Result.SecurityFilters -DifferenceObject (Get-NetFirewallSecurityFilter -AssociatedNetFirewallRule $FirewallRule)).Count | Should Be 0
                @(Compare-Object -ReferenceObject $Result.ServiceFilters -DifferenceObject (Get-NetFirewallServiceFilter -AssociatedNetFirewallRule $FirewallRule)).Count | Should Be 0
            }
        }
        Context 'testing with only AddressFilter property requested' {
            It 'should return only AddressFilter property' {
                $Result = Get-FirewallRuleProperty -FirewallRule $FirewallRule -Property AddressFilter
                @(Compare-Object -ReferenceObject $Result -DifferenceObject (Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $FirewallRule)).Count | Should Be 0
                $Result.ApplicationFilters | Should BeNullOrEmpty
                $Result.InterfaceFilters | Should BeNullOrEmpty
                $Result.InterfaceTypeFilters | Should BeNullOrEmpty
                $Result.PortFilters | Should BeNullOrEmpty
                $Result.Profile | Should BeNullOrEmpty
                $Result.SecurityFilters | Should BeNullOrEmpty
                $Result.ServiceFilters | Should BeNullOrEmpty
            }
        }
        Context 'testing with only ApplicationFilters property requested' {
            It 'should return only ApplicationFilters property' {
                $Result = Get-FirewallRuleProperty -FirewallRule $FirewallRule -Property ApplicationFilter
                $Result.AddressFilters | Should BeNullOrEmpty
                @(Compare-Object -ReferenceObject $Result -DifferenceObject (Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $FirewallRule)).Count | Should Be 0
                $Result.InterfaceFilters | Should BeNullOrEmpty
                $Result.InterfaceTypeFilters | Should BeNullOrEmpty
                $Result.PortFilters | Should BeNullOrEmpty
                $Result.Profile | Should BeNullOrEmpty
                $Result.SecurityFilters | Should BeNullOrEmpty
                $Result.ServiceFilters | Should BeNullOrEmpty
            }
        }
        Context 'testing with only InterfaceFilters property requested' {
            It 'should return only InterfaceFilters property' {
                $Result = Get-FirewallRuleProperty -FirewallRule $FirewallRule -Property InterfaceFilter
                $Result.ApplicationFilters | Should BeNullOrEmpty
                $Result.AddressFilters | Should BeNullOrEmpty
                @(Compare-Object -ReferenceObject $Result -DifferenceObject (Get-NetFirewallInterfaceFilter -AssociatedNetFirewallRule $FirewallRule)).Count | Should Be 0
                $Result.InterfaceTypeFilters | Should BeNullOrEmpty
                $Result.PortFilters | Should BeNullOrEmpty
                $Result.Profile | Should BeNullOrEmpty
                $Result.SecurityFilters | Should BeNullOrEmpty
                $Result.ServiceFilters | Should BeNullOrEmpty
            }
        }
        Context 'testing with only InterfaceTypeFilters property requested' {
            It 'should return only InterfaceTypeFilters property' {
                $Result = Get-FirewallRuleProperty -FirewallRule $FirewallRule -Property InterfaceTypeFilter
                $Result.ApplicationFilters | Should BeNullOrEmpty
                $Result.AddressFilters | Should BeNullOrEmpty
                $Result.InterfaceFilters | Should BeNullOrEmpty
                @(Compare-Object -ReferenceObject $Result -DifferenceObject (Get-NetFirewallInterfaceTypeFilter -AssociatedNetFirewallRule $FirewallRule)).Count | Should Be 0
                $Result.PortFilters | Should BeNullOrEmpty
                $Result.Profile | Should BeNullOrEmpty
                $Result.SecurityFilters | Should BeNullOrEmpty
                $Result.ServiceFilters | Should BeNullOrEmpty
            }
        }
        Context 'testing with only PortFilters property requested' {
            It 'should return only PortFilters property' {
                $Result = Get-FirewallRuleProperty -FirewallRule $FirewallRule -Property PortFilter
                $Result.ApplicationFilters | Should BeNullOrEmpty
                $Result.AddressFilters | Should BeNullOrEmpty
                $Result.InterfaceFilters | Should BeNullOrEmpty
                $Result.InterfaceTypeFilters | Should BeNullOrEmpty
                @(Compare-Object -ReferenceObject $Result -DifferenceObject (Get-NetFirewallPortFilter -AssociatedNetFirewallRule $FirewallRule)).Count | Should Be 0
                $Result.Profile | Should BeNullOrEmpty
                $Result.SecurityFilters | Should BeNullOrEmpty
                $Result.ServiceFilters | Should BeNullOrEmpty
            }
        }
        Context 'testing with only Profile property requested' {
            It 'should return only Profile property' {
                $Result = Get-FirewallRuleProperty -FirewallRule $FirewallRule -Property Profile
                $Result.ApplicationFilters | Should BeNullOrEmpty
                $Result.AddressFilters | Should BeNullOrEmpty
                $Result.InterfaceFilters | Should BeNullOrEmpty
                $Result.InterfaceTypeFilters | Should BeNullOrEmpty
                $Result.PortFilters | Should BeNullOrEmpty
                @(Compare-Object -ReferenceObject $Result -DifferenceObject (Get-NetFirewallProfile -AssociatedNetFirewallRule $FirewallRule)).Count | Should Be 0
                $Result.SecurityFilters | Should BeNullOrEmpty
                $Result.ServiceFilters | Should BeNullOrEmpty
            }
        }
        Context 'testing with only SecurityFilters property requested' {
            It 'should return only SecurityFilters property' {
                $Result = Get-FirewallRuleProperty -FirewallRule $FirewallRule -Property SecurityFilter
                $Result.ApplicationFilters | Should BeNullOrEmpty
                $Result.AddressFilters | Should BeNullOrEmpty
                $Result.InterfaceFilters | Should BeNullOrEmpty
                $Result.InterfaceTypeFilters | Should BeNullOrEmpty
                $Result.PortFilters | Should BeNullOrEmpty
                $Result.Profile | Should BeNullOrEmpty
                @(Compare-Object -ReferenceObject $Result -DifferenceObject (Get-NetFirewallSecurityFilter -AssociatedNetFirewallRule $FirewallRule)).Count | Should Be 0
                $Result.ServiceFilters | Should BeNullOrEmpty
            }
        }
        Context 'testing with only ServiceFilters property requested' {
            It 'should return only ServiceFilters property' {
                $Result = Get-FirewallRuleProperty -FirewallRule $FirewallRule -Property ServiceFilter
                $Result.ApplicationFilters | Should BeNullOrEmpty
                $Result.AddressFilters | Should BeNullOrEmpty
                $Result.InterfaceFilters | Should BeNullOrEmpty
                $Result.InterfaceTypeFilters | Should BeNullOrEmpty
                $Result.PortFilters | Should BeNullOrEmpty
                $Result.Profile | Should BeNullOrEmpty
                $Result.SecurityFilters | Should BeNullOrEmpty
                @(Compare-Object -ReferenceObject $Result -DifferenceObject (Get-NetFirewallServiceFilter -AssociatedNetFirewallRule $FirewallRule)).Count | Should Be 0
            }
        }
    }
}
