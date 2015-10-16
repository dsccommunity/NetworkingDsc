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

InModuleScope $DSCResourceName {

######################################################################################

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
            $rule = Get-NetFirewallRule | Sort-Object Name | Where-Object {$_.DisplayGroup -ne $null} | Select-Object -first 1
            $ruleProperties = Get-FirewallRuleProperty $rule

            $result = Get-TargetResource -Name $rule.Name

            It 'should have the correct DisplayName and type' {
                $result.DisplayName | Should Be $rule.DisplayName
                $result.DisplayName.GetType() | Should Be $rule.DisplayName.GetType()
            }

            It 'Should have the correct Group and type' {
                $result.Group | Should Be $rule.Group
                $result.Group.GetType() | Should Be $rule.Group.GetType()
            }

            It 'Should have the correct DisplayGroup and type' {
                $result.DisplayGroup | Should Be $rule.DisplayGroup
                $result.DisplayGroup.GetType() | Should Be $rule.DisplayGroup.GetType()
            }

            It 'Should have the correct Profile' {
                $result.Profile[0] | Should Be ($rule.Profile.ToString() -replace(' ', '') -split(','))[0]
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

            It 'Should have the correct Action' {
                $result.Action | Should Be $rule.Action
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

######################################################################################

    Describe 'Test-TargetResource' {
        $rule = Get-NetFirewallRule | `
            Where-Object {$_.DisplayName -ne $null} | `
            Select-Object -first 1

        Context 'Ensure is Absent and the Firewall is not Present' {
            Mock Get-FirewallRule

            It 'should return $true' {
                $result = Test-TargetResource -Name 'FirewallRule' -Ensure 'Absent'
                $result | Should Be $true
            }
        }
        Context 'Ensure is Absent and the Firewall is Present' {
            Mock Test-RuleProperties

            It 'should return $false' {
                $result = Test-TargetResource -Name $rule.Name -Ensure 'Absent'
                $result | Should Be $false
            }
        }
        Context 'Ensure is Present and the Firewall is Present and properties match' {
            Mock Test-RuleProperties -MockWith { return $true }

            It 'should return $true' {
                $result = Test-TargetResource -Name $rule.Name
                $result | Should Be $true
            }
        }
        Context 'Ensure is Present and the Firewall is Present and properties are different' {
            Mock Test-RuleProperties -MockWith { return $false }

            It 'should return $false' {
                $result = Test-TargetResource -Name $rule.Name
                $result | Should Be $false
            }
        }
        Context 'Ensure is Present and the Firewall is Absent' {
            It 'should return $false' {
                $result = Test-TargetResource -Name $rule.Name
                $result | Should Be $false
            }
        }
    }

######################################################################################

    Describe 'Set-TargetResource' {
        $rule = Get-NetFirewallRule | Where-Object {$_.DisplayName -ne $null} |
            Select-Object -First 1

        Context 'Ensure is Absent and Firewall Exist' {
            It "should call expected mocks on firewall rule $($rule.Name)" {
                Mock Remove-NetFirewallRule
                $result = Set-TargetResource -Name $rule.Name -Ensure 'Absent'

                Assert-MockCalled Remove-NetFirewallRule -Exactly 1
            }
        }
        Context 'Ensure is Absent and the Firewall Does Not Exist' {
            It "should call expected mocks on firewall rule $($rule.Name)" {
                Mock Get-FirewallRule
                Mock Remove-NetFirewallRule
                $result = Set-TargetResource -Name $rule.Name -Ensure 'Absent'

                Assert-MockCalled Remove-NetFirewallRule -Exactly 0
            }
        }
        Context 'Ensure is Present and the Firewall Does Not Exist' {
            It "should call expected mocks on firewall rule $($rule.Name)" {
                Mock Get-FirewallRule
                Mock New-NetFirewallRule
                $result = Set-TargetResource -Name $rule.Name -Ensure 'Present'

                Assert-MockCalled New-NetFirewallRule -Exactly 1
                Assert-MockCalled Get-FirewallRule -Exactly 1
            }
        }
        Context 'Ensure is Present and the Firewall Does Exist but is different' {
            It "should call expected mocks on firewall rule $($rule.Name)" {
                Mock Set-NetFirewallRule
                Mock Test-RuleProperties {return $false}
                $result = Set-TargetResource -Name $rule.Name -Ensure 'Present'

                Assert-MockCalled Set-NetFirewallRule -Exactly 1
                Assert-MockCalled Test-RuleProperties -Exactly 1
            }
        }
        Context 'Ensure is Present and the Firewall Does Exist and is the same' {
            It "should call expected mocks on firewall rule $($rule.Name)" {
                Mock Set-NetFirewallRule
                Mock Test-RuleProperties {return $true}
                $result = Set-TargetResource -Name $rule.Name -Ensure 'Present'

                Assert-MockCalled Set-NetFirewallRule -Exactly 0
                Assert-MockCalled Test-RuleProperties -Exactly 1
            }
        }

    }

######################################################################################

    Describe 'Test-RuleProperties' {
        $rule = Get-NetFirewallRule | Where-Object {$_.DisplayName -ne $null} |
                    Select-Object -First 1
        $FirewallRule = Get-FirewallRule -Name $rule.name
        $Properties = Get-FirewallRuleProperty -FirewallRule $FirewallRule

        # Make an object that can be splatted onto the function
        $Splat = @{
            Name = $FirewallRule.Name
            DisplayGroup = $FirewallRule.DisplayGroup
            Enabled = $FirewallRule.Enabled
            Profile = $FirewallRule.Profile.ToString() -replace(' ', '') -split(',')
            Direction = $FirewallRule.Direction
            Action = $FirewallRule.Action
            RemotePort = $Properties.PortFilters.RemotePort
            LocalPort = $Properties.PortFilters.LocalPort
            Protocol = $Properties.PortFilters.Protocol
            Description = $FirewallRule.Description
            ApplicationPath = $Properties.ApplicationFilters.Program
            Service = $Properties.ServiceFilters.Service
        }

        # To speed up all these tests create Mocks so that these functions are not repeatedly called
        Mock Get-FirewallRule -MockWith { $FirewallRule }
        Mock Get-FirewallRuleProperty -MockWith { $Properties }

        Context 'testing with a rule with no property differences' {
            $CompareRule = $Splat.Clone()
            It 'should return True' {
                $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $True
            }
        }
        Context 'testing with a rule with a different name' {
            $CompareRule = $Splat.Clone()
            $CompareRule.Name = 'Different'
            It 'should return False' {
                $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different enabled' {
            $CompareRule = $Splat.Clone()
            $CompareRule.Enabled = if( $CompareRule.Enabled -eq 'True' ) {'False'} Else {'True'}
            It 'should return False' {
                $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different action' {
            $CompareRule = $Splat.Clone()
            $CompareRule.Action = if ($CompareRule.Action -eq 'Allow') {'Block'} else {'Allow'}
            It 'should return False' {
                $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different profile' {
            $CompareRule = $Splat.Clone()
            $CompareRule.Profile = 'Different'
            It 'should return False' {
                $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different direction' {
            $CompareRule = $Splat.Clone()
            $CompareRule.Direction = if ($CompareRule.Direction -eq 'Inbound') {'Outbound'} else {'Inbound'}
            It 'should return False' {
                $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different remote port' {
            $CompareRule = $Splat.Clone()
            $CompareRule.RemotePort = 1
            It 'should return False' {
                $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different local port' {
            $CompareRule = $Splat.Clone()
            $CompareRule.LocalPort = 1
            It 'should return False' {
                $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different protocol' {
            $CompareRule = $Splat.Clone()
            $CompareRule.Protocol = 'Different'
            It 'should return False' {
                $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different description' {
            $CompareRule = $Splat.Clone()
            $CompareRule.Description = 'Different'
            It 'should return False' {
                $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different application path' {
            $CompareRule = $Splat.Clone()
            $CompareRule.ApplicationPath = 'Different'
            It 'should return False' {
                $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different description' {
            $CompareRule = $Splat.Clone()
            $CompareRule.Service = 'Different'
            It 'should return False' {
                $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
    }

######################################################################################

    Describe ' Get-FirewallRule' {
        $rule = Get-NetFirewallRule | Select-Object -First 1
        $rules = Get-NetFirewallRule | Select-Object -First 2

        Context 'testing with firewall that exists' {
            It 'should return a firewall rule when name is passed' {
                $Result = Get-FirewallRule -Name $rule.Name
                $Result | Should Not BeNullOrEmpty
            }
        }
        Context 'testing with firewall that does not exist' {
            It 'should not return anything' {
                $Result = Get-FirewallRule -Name 'Does not exist'
                $Result | Should BeNullOrEmpty
            }
        }
        Context 'testing with firewall that somehow occurs more than once' {
            Mock Get-NetFirewallRule -MockWith { $rules }

            $errorId = 'RuleNotUnique'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
            $errorMessage = $($LocalizedData.RuleNotUniqueError) -f 2,$rule.Name
            $exception = New-Object -TypeName System.InvalidOperationException `
                -ArgumentList $errorMessage
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                -ArgumentList $exception, $errorId, $errorCategory, $null

            It 'should throw RuleNotUnique exception' {
                { $Result = Get-FirewallRule -Name $rule.Name } | Should Throw $errorRecord
            }
        }
    }

######################################################################################

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

######################################################################################

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
