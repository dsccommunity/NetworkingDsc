$DSCResourceName = 'MSFT_xFirewall'
$DSCModuleName   = 'xNetworking'

$Splat = @{
    Path = $PSScriptRoot
    ChildPath = "..\..\DSCResources\$DSCResourceName\$DSCResourceName.psm1"
    Resolve = $true
    ErrorAction = 'Stop'
}

$DSCResourceModuleFile = Get-Item -Path (Join-Path @Splat)

if (Get-Module -Name $DSCResourceName)
{
    Remove-Module -Name $DSCResourceName
}

Import-Module -Name $DSCResourceModuleFile.FullName -Force

$moduleRoot = "${env:ProgramFiles}\WindowsPowerShell\Modules\$DSCModuleName"

if(-not (Test-Path -Path $moduleRoot))
{
    $null = New-Item -Path $moduleRoot -ItemType Directory
}
else
{
    # Copy the existing folder out to the temp directory to hold until the end of the run
    # Delete the folder to remove the old files.
    $tempLocation = Join-Path -Path $env:Temp -ChildPath $DSCModuleName
    Copy-Item -Path $moduleRoot -Destination $tempLocation -Recurse -Force
    Remove-Item -Path $moduleRoot -Recurse -Force
    $null = New-Item -Path $moduleRoot -ItemType Directory
}

Copy-Item -Path $PSScriptRoot\..\..\* -Destination $moduleRoot -Recurse -Force -Exclude '.git'

InModuleScope $DSCResourceName {
    Describe 'Get-TargetResource' {
        Context 'Absent should return correctly' {
            Mock Get-NetFirewallRule

            It 'Should return absent' {
                $result = Get-TargetResource -Name 'FirewallRule'
                $result.Name | Should Be 'FirewallRule'
                $result.Ensure | Should Be 'Absent'
            }
        }

        Context 'Present should return correctly' {
            $firewall = Get-NetFirewallRule | select -first 1
            $ruleProperties = Get-FirewallRuleProperty $firewall

            $result = Get-TargetResource -Name $firewall.Name

            It 'should have the correct DisplayName and type' {
                $result.DisplayName | Should Be $firewall.DisplayName
                $result.DisplayName.GetType() | Should Be $firewall.DisplayName.GetType()
            }

            It 'Should have the correct DisplayGroup and type' {
                $result.DisplayGroup | Should Be $firewall.DisplayGroup
                $result.DisplayGroup.GetType() | Should Be $firewall.DisplayGroup.GetType()
            }

            It 'Should have the correct Profile' {
                $result.Profile | Should Be $firewall.Profile
            }

            It 'Should have the correct Direction and type' {
                $result.Direction | Should Be $firewall.Direction
                $result.Direction.GetType() | Should Be $firewall.Direction.GetType()
            }

            It 'Should have the correct Description and type' {
                $result.Description | Should Be $firewall.Description
                $result.Description.GetType() | Should Be $firewall.Description.GetType()
            }

            It 'Should have the correct RemotePort and type' {
                $result.RemotePort | Should Be $ruleProperties.PortFilters.RemotePort
            }

            It 'Should have the correct LocalPort and type' {
                $result.LocalPort | Should Be $ruleProperties.PortFilters.LocalPort
            }

            It 'Should have the correct Protocol and type' {
                $result.Protocol | Should Be $ruleProperties.PortFilters.Protocol
            }

            It 'Should have the correct ApplicationPath and type' {
                $result.ApplicationPath | Should Be $ruleProperties.ApplicationFilters.Program
            }

            It 'Should have the correct Service and type' {
                $result.Service | Should Be $ruleProperties.ServiceFilters.Service
            }
        }
    }

    Describe 'Test-TargetResource' {
        Context 'Ensure is Absent and the Firewall is not Present' {
            It 'should return $true' {
                Mock Get-FirewallRule
                $result = Test-TargetResource -Name 'FirewallRule' -Ensure 'Absent'
                $result | should be $true
            }
        }
        Context 'Ensure is Absent and the Firewall is Present' {
            It 'should return $false' {
                $firewall = Get-NetFirewallRule | Where-Object {$_.DisplayName -ne $null} | select -first 1
                Mock Test-RuleProperties

                $result = Test-TargetResource -Name $firewall.Name -DisplayName $firewall.DisplayName -Ensure 'Absent'
                $result | should be $false
            }
        }
        Context 'Ensure is Present and the Firewall is Present' {
            It 'should return $true' {
                $firewall = Get-NetFirewallRule | Where-Object {$_.DisplayName -ne $null} | select -first 1
                $result = Test-TargetResource -Name $firewall.Name -DisplayName $firewall.DisplayName
                $result | should be $true
            }
        }
        Context 'Ensure is Present and the Firewall is Absent' {
            It 'should return $false' {
                $firewall = Get-NetFirewallRule | Where-Object {$_.DisplayName -ne $null} | select -first 1
                Mock Test-RuleProperties
                $result = Test-TargetResource -Name $firewall.Name -DisplayName $firewall.DisplayName -Ensure 'Absent'
                $result | should be $false
            }
        }
    }

    Describe 'Set-TargetResource' {
        $firewall = Get-NetFirewallRule | Where-Object {$_.DisplayName -ne $null} | Select-Object -First 1
        Context 'Ensure is Absent and Firewall Exists' {
            It "should call all the mocks on firewall rule $($firewall.Name)" {
                Mock Remove-NetFirewallRule
                $result = Set-TargetResource -Name $firewall.Name -Ensure 'Absent'
                Assert-MockCalled Remove-NetFirewallRule -Exactly 1
            }
        }
        Context 'Ensure is Absent and the Firewall Does Not Exists' {
            It "should call all the mocks on firewall rule $($firewall.Name)" {
                Mock Get-FirewallRule
                Mock Remove-NetFirewallRule
                $result = Set-TargetResource -Name $firewall.Name -Ensure 'Absent'
                Assert-MockCalled Remove-NetFirewallRule -Exactly 0
            }
        }
        Context 'Ensure is Present and the Firewall Does Not Exists' {
            It "should call all the mocks on firewall rule $($firewall.Name)" {
                Mock Get-FirewallRule
                Mock New-NetFirewallRule
                $result = Set-TargetResource -Name $firewall.Name -Ensure 'Present' #-DisplayName $firewall.Name
                Assert-MockCalled New-NetFirewallRule -Exactly 1
                Assert-MockCalled Get-FirewallRule -Exactly 1

            }
        }
        Context 'Ensure is Present and the Firewall Does Exists' {
            It "should call all the mocks on firewall rule $($firewall.Name)" {
                Mock Remove-NetFirewallRule
                Mock New-NetFirewallRule
                Mock Test-RuleProperties {return $false}
                $result = Set-TargetResource -Name $firewall.Name -Ensure 'Present' #-DisplayName $firewall.Name
                Assert-MockCalled New-NetFirewallRule -Exactly 1
                Assert-MockCalled Remove-NetFirewallRule -Exactly 1
                Assert-MockCalled Test-RuleProperties -Exactly 1
            }
        }
    }

    Describe 'Get-FirewallRuleProperty' {
        $firewall = Get-NetFirewallRule | Where-Object {$_.DisplayName -ne $null} | Select-Object -First 1

        Context 'All Properties' {
            $result = Get-FirewallRuleProperty -FirewallRule $firewall
            It 'Should return the right address filter' {
                $expected = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $firewall
                $($result.AddressFilters | out-string -stream) | Should Be $($expected | out-string -stream)
            }

            It 'Should return the right application filter' {
                $expected = Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $firewall
                $($result.ApplicationFilters | out-string -stream) | Should Be $($expected | out-string -stream)
            }

            It 'Should return the right interface filter' {
                $expected = Get-NetFirewallInterfaceFilter -AssociatedNetFirewallRule $firewall
                $($result.InterfaceFilters | out-string -stream) | Should Be $($expected | out-string -stream)
            }

            It 'Should return the right interface type filter' {
                $expected = Get-NetFirewallInterfaceTypeFilter -AssociatedNetFirewallRule $firewall
                $($result.InterfaceTypeFilters | out-string -stream) | Should Be $($expected | out-string -stream)
            }

            It 'Should return the right port filter' {
                $expected = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $firewall
                $($result.PortFilters | out-string -stream) | Should Be $($expected | out-string -stream)
            }

            It 'Should return the right Profile' {
                $expected = Get-NetFirewallProfile -AssociatedNetFirewallRule $firewall
                $($result.Profile | out-string -stream) | Should Be $($expected | out-string -stream)
            }

            It 'Should return the right Profile' {
                $expected = Get-NetFirewallProfile -AssociatedNetFirewallRule $firewall
                $($result.Profile | out-string -stream) | Should Be $($expected | out-string -stream)
            }

            It 'Should return the right Security Filters' {
                $expected = Get-NetFirewallSecurityFilter -AssociatedNetFirewallRule $firewall
                $($result.SecurityFilters | out-string -stream) | Should Be $($expected | out-string -stream)
            }

            It 'Should return the right Service Filters' {
                $expected = Get-NetFirewallServiceFilter -AssociatedNetFirewallRule $firewall
                $($result.ServiceFilters | out-string -stream) | Should Be $($expected | out-string -stream)
            }
        }
    }
}

# Clean up after the test completes.
Remove-Item -Path $moduleRoot -Recurse -Force

# Restore previous versions, if it exists.
if ($tempLocation)
{
    $null = New-Item -Path $moduleRoot -ItemType Directory
    Copy-Item -Path $tempLocation -Destination "${env:ProgramFiles}\WindowsPowerShell\Modules" -Recurse -Force
    Remove-Item -Path $tempLocation -Recurse -Force
}
