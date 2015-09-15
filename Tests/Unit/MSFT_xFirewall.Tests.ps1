$DSCResourceName = 'MSFT_xFirewall'
$DSCModuleName   = 'xNetworking'

$Splat = @{
    Path = $PSScriptRoot
    ChildPath = "..\..\DSCResources\$DSCResourceName\$DSCResourceName.psm1"
    Resolve = $true
    ErrorAction = 'Stop'
}

$DSCResourceModuleFile = Get-Item -Path (Join-Path @Splat)

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

if (Get-Module -Name $DSCResourceName)
{
    Remove-Module -Name $DSCResourceName
}

Import-Module -Name $DSCResourceModuleFile.FullName -Force

$breakvar = $True

InModuleScope $DSCResourceName {
    Describe 'Get-TargetResource' {
        Context 'Absent should return correctly' {
            Mock Get-NetFirewallRule

                $breakvar = $true;

            It 'Should return absent' {
                $result = Get-TargetResource -Name 'FirewallRule'
                $result.Name | Should Be 'FirewallRule'
                $result.Ensure | Should Be 'Absent'
            }
        }

        Context 'Present should return correctly' {
            $rule = Get-NetFirewallRule | Sort-Object Name | Where-Object {$_.DisplayGroup -ne $null} | Select-Object -first 1
            $ruleProperties = Get-FirewallRuleProperty $rule

            $result = Get-TargetResource -Name $rule.Name

            It 'should have the correct DisplayName and type' {
                $result.DisplayName | Should Be $rule.DisplayName
                $result.DisplayName.GetType() | Should Be $rule.DisplayName.GetType()
            }

            It 'Should have the correct DisplayGroup and type' {
                $result.DisplayGroup | Should Be $rule.DisplayGroup
                $result.DisplayGroup.GetType() | Should Be $rule.DisplayGroup.GetType()
            }

            It 'Should have the correct Profile' {
                $result.Profile[0] | Should Be ($rule.Profile.ToString() -replace(" ", "") -split(","))[0]
            }

            It 'Should have the correct Direction and type' {
                $result.Direction | Should Be $rule.Direction
                $result.Direction.GetType() | Should Be $rule.Direction.GetType()
            }

            It 'Should have the correct Description and type' {
                $result.Description | Should Be $rule.Description
                $result.Description.GetType() | Should Be $rule.Description.GetType()
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
        $rule = Get-NetFirewallRule | `
            Where-Object {$_.DisplayName -ne $null} | `
            Select-Object -first 1

        Context 'Ensure is Absent and the Firewall is not Present' {
            It 'should return $true' {
                Mock Get-FirewallRule
                $result = Test-TargetResource -Name 'FirewallRule' -Ensure 'Absent'
                $result | Should Be $true
            }
        }
        Context 'Ensure is Absent and the Firewall is Present' {
            It 'should return $false' {
                Mock Test-RuleProperties

                $result = Test-TargetResource -Name $rule.Name `
                    -DisplayName $rule.DisplayName `
                    -Ensure 'Absent'

                $result | Should Be $false
            }
        }
        Context 'Ensure is Present and the Firewall is Present' {
            It 'should return $true' {
                $result = Test-TargetResource `
                    -Name $rule.Name `
                    -DisplayName $rule.DisplayName

                $result | Should Be $true
            }
        }
        Context 'Ensure is Present and the Firewall is Absent' {
            It 'should return $false' {
                Mock Test-RuleProperties
                $result = Test-TargetResource `
                    -Name $rule.Name `
                    -DisplayName $rule.DisplayName -Ensure 'Absent'

                $result | Should Be $false
            }
        }
    }

    Describe 'Set-TargetResource' {
        $rule = Get-NetFirewallRule | Where-Object {$_.DisplayName -ne $null} |
            Select-Object -First 1

        Context 'Ensure is Absent and Firewall Exists' {
            It "should call all the mocks on firewall rule $($rule.Name)" {
                Mock Remove-NetFirewallRule
                $result = Set-TargetResource -Name $rule.Name -Ensure 'Absent'

                Assert-MockCalled Remove-NetFirewallRule -Exactly 1
            }
        }
        Context 'Ensure is Absent and the Firewall Does Not Exists' {
            It "should call all the mocks on firewall rule $($rule.Name)" {
                Mock Get-FirewallRule
                Mock Remove-NetFirewallRule
                $result = Set-TargetResource -Name $rule.Name -Ensure 'Absent'

                Assert-MockCalled Remove-NetFirewallRule -Exactly 0
            }
        }
        Context 'Ensure is Present and the Firewall Does Not Exists' {
            It "should call all the mocks on firewall rule $($rule.Name)" {
                Mock Get-FirewallRule
                Mock New-NetFirewallRule
                $result = Set-TargetResource -Name $rule.Name -Ensure 'Present'

                Assert-MockCalled New-NetFirewallRule -Exactly 1
                Assert-MockCalled Get-FirewallRule -Exactly 1
            }
        }
        Context 'Ensure is Present and the Firewall Does Exists' {
            It "should call all the mocks on firewall rule $($rule.Name)" {
                Mock Remove-NetFirewallRule
                Mock New-NetFirewallRule
                Mock Test-RuleProperties {return $false}
                $result = Set-TargetResource -Name $rule.Name -Ensure 'Present'

                Assert-MockCalled New-NetFirewallRule -Exactly 1
                Assert-MockCalled Remove-NetFirewallRule -Exactly 1
                Assert-MockCalled Test-RuleProperties -Exactly 1
            }
        }
    }

    Describe 'Get-FirewallRuleProperty' {
        $rule = Get-NetFirewallRule | Where-Object {$_.DisplayName -ne $null} |
            Select-Object -First 1

        Context 'All Properties' {
            $result = Get-FirewallRuleProperty -FirewallRule $rule
            It 'Should return the right address filter' {
                $expected = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $rule

                $($result.AddressFilters | Out-String -Stream) |
                    Should Be $($expected | Out-String -Stream)
            }

            It 'Should return the right application filter' {
                $expected = Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $rule

                $($result.ApplicationFilters | Out-String -Stream) |
                    Should Be $($expected | Out-String -Stream)
            }

            It 'Should return the right interface filter' {
                $expected = Get-NetFirewallInterfaceFilter -AssociatedNetFirewallRule $rule

                $($result.InterfaceFilters | Out-String -Stream) |
                    Should Be $($expected | Out-String -Stream)
            }

            It 'Should return the right interface type filter' {
                $expected = Get-NetFirewallInterfaceTypeFilter -AssociatedNetFirewallRule $rule
                $($result.InterfaceTypeFilters | Out-String -Stream) |
                    Should Be $($expected | Out-String -Stream)
            }

            It 'Should return the right port filter' {
                $expected = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $rule
                $($result.PortFilters | Out-String -Stream) |
                    Should Be $($expected | Out-String -Stream)
            }

            It 'Should return the right Profile' {
                $expected = Get-NetFirewallProfile -AssociatedNetFirewallRule $rule
                $($result.Profile | Out-String -Stream) |
                    Should Be $($expected | Out-String -Stream)
            }

            It 'Should return the right Profile' {
                $expected = Get-NetFirewallProfile -AssociatedNetFirewallRule $rule
                $($result.Profile | Out-String -Stream) |
                    Should Be $($expected | Out-String -Stream)
            }

            It 'Should return the right Security Filters' {
                $expected = Get-NetFirewallSecurityFilter -AssociatedNetFirewallRule $rule
                $($result.SecurityFilters | Out-String -Stream) |
                    Should Be $($expected | Out-String -Stream)
            }

            It 'Should return the right Service Filters' {
                $expected = Get-NetFirewallServiceFilter -AssociatedNetFirewallRule $rule
                $($result.ServiceFilters | Out-String -Stream) |
                    Should Be $($expected | Out-String -Stream)
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
    $script:Destination = "${env:ProgramFiles}\WindowsPowerShell\Modules"
    Copy-Item -Path $tempLocation -Destination $script:Destination -Recurse -Force
    Remove-Item -Path $tempLocation -Recurse -Force
}
