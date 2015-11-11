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
            $FirewallRule = Get-NetFirewallRule | Sort-Object Name | Where-Object {$_.DisplayGroup -ne $null} | Select-Object -first 1
            $Properties = Get-FirewallRuleProperty $FirewallRule

            $result = Get-TargetResource -Name $FirewallRule.Name

            # Looping these tests
            foreach ($p in $ParameterList)
            {
                $ParameterSource = (Invoke-Expression -Command "`$($($p.source))")
                $ParameterNew = (Invoke-Expression -Command "`$result.$($p.name)")
                It "should have the correct $($p.Name)" {
                    $ParameterSource | Should Be $ParameterSource
                }
            }
        }
    }

######################################################################################

    Describe 'Test-TargetResource' {
        $FirewallRule = Get-NetFirewallRule | `
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
                $result = Test-TargetResource -Name $FirewallRule.Name -Ensure 'Absent'
                $result | Should Be $false
            }
        }
        Context 'Ensure is Present and the Firewall is Present and properties match' {
            Mock Test-RuleProperties -MockWith { return $true }

            It 'should return $true' {
                $result = Test-TargetResource -Name $FirewallRule.Name
                $result | Should Be $true
            }
        }
        Context 'Ensure is Present and the Firewall is Present and properties are different' {
            Mock Test-RuleProperties -MockWith { return $false }

            It 'should return $false' {
                $result = Test-TargetResource -Name $FirewallRule.Name
                $result | Should Be $false
            }
        }
        Context 'Ensure is Present and the Firewall is Absent' {
            It 'should return $false' {
                $result = Test-TargetResource -Name $FirewallRule.Name
                $result | Should Be $false
            }
        }
    }

######################################################################################

    Describe 'Set-TargetResource' {
        $FirewallRule = Get-NetFirewallRule | Where-Object {$_.DisplayName -ne $null} |
            Select-Object -First 1

        Context 'Ensure is Absent and Firewall Exist' {
            It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                Mock Remove-NetFirewallRule
                $result = Set-TargetResource -Name $FirewallRule.Name -Ensure 'Absent'

                Assert-MockCalled Remove-NetFirewallRule -Exactly 1
            }
        }
        Context 'Ensure is Absent and the Firewall Does Not Exist' {
            It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                Mock Get-FirewallRule
                Mock Remove-NetFirewallRule
                $result = Set-TargetResource -Name $FirewallRule.Name -Ensure 'Absent'

                Assert-MockCalled Remove-NetFirewallRule -Exactly 0
            }
        }
        Context 'Ensure is Present and the Firewall Does Not Exist' {
            It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                Mock Get-FirewallRule
                Mock New-NetFirewallRule
                $result = Set-TargetResource -Name $FirewallRule.Name -Ensure 'Present'

                Assert-MockCalled New-NetFirewallRule -Exactly 1
                Assert-MockCalled Get-FirewallRule -Exactly 1
            }
        }
        Context 'Ensure is Present and the Firewall Does Exist but has a different DisplayName' {
            It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                Mock Set-NetFirewallRule
                Mock Test-RuleProperties {return $false}
                $result = Set-TargetResource `
                    -Name $FirewallRule.Name `
                    -DisplayName 'Different' `
                    -Ensure 'Present'

                Assert-MockCalled Set-NetFirewallRule -Exactly 1
                Assert-MockCalled Test-RuleProperties -Exactly 1
            }
        }
        Context 'Ensure is Present and the Firewall Does Exist but has a different Group' {
            It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                Mock New-NetFirewallRule
                Mock Remove-NetFirewallRule
                Mock Test-RuleProperties {return $false}
                $result = Set-TargetResource `
                    -Name $FirewallRule.Name `
                    -DisplayName $FirewallRule.DisplayName `
                    -Group 'Different' `
                    -Ensure 'Present'

                Assert-MockCalled New-NetFirewallRule -Exactly 1
                Assert-MockCalled Remove-NetFirewallRule -Exactly 1
                Assert-MockCalled Test-RuleProperties -Exactly 1
            }
        }
        Context 'Ensure is Present and the Firewall Does Exist but has a different Enabled' {
            It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                Mock Set-NetFirewallRule
                Mock Test-RuleProperties {return $false}
                if( $FirewallRule.Enabled -eq 'True' ) {
                    $NewEnabled = 'False'
                }
                else
                {
                    $NewEnabled = 'True'
                }
                $result = Set-TargetResource `
                    -Name $FirewallRule.Name `
                    -Enabled $NewEnabled `
                    -Ensure 'Present'

                Assert-MockCalled Set-NetFirewallRule -Exactly 1
                Assert-MockCalled Test-RuleProperties -Exactly 1
            }
        }
        Context 'Ensure is Present and the Firewall Does Exist but has a different Action' {
            It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                Mock Set-NetFirewallRule
                Mock Test-RuleProperties {return $false}
                if ( $FirewallRule.Action -eq 'Allow') {
                    $NewAction = 'Block'
                }
                else
                {
                    $NewAction = 'Allow'
                }
                $result = Set-TargetResource `
                    -Name $FirewallRule.Name `
                    -Action $NewAction `
                    -Ensure 'Present'

                Assert-MockCalled Set-NetFirewallRule -Exactly 1
                Assert-MockCalled Test-RuleProperties -Exactly 1
            }
        }
        Context 'Ensure is Present and the Firewall Does Exist but has a different Profile' {
            It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                Mock Set-NetFirewallRule
                Mock Test-RuleProperties {return $false}
                if ( $FirewallRule.Profile -ccontains 'Domain') {
                    $NewProfile = @('Public','Private')
                }
                else
                {
                    $NewProfile = @('Domain','Public')
                }
                $result = Set-TargetResource `
                    -Name $FirewallRule.Name `
                    -Profile $NewProfile `
                    -Ensure 'Present'

                Assert-MockCalled Set-NetFirewallRule -Exactly 1
                Assert-MockCalled Test-RuleProperties -Exactly 1
            }
        }
        Context 'Ensure is Present and the Firewall Does Exist but has a different Direction' {
            It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                Mock Set-NetFirewallRule
                Mock Test-RuleProperties {return $false}
                if ( $FirewallRule.Direction -eq 'Inbound') {
                    $NewDirection = 'Outbound'
                }
                    else
                {
                    $NewDirection = 'Inbound'
                }
                $result = Set-TargetResource `
                    -Name $FirewallRule.Name `
                    -Direction $NewDirection `
                    -Ensure 'Present'

                Assert-MockCalled Set-NetFirewallRule -Exactly 1
                Assert-MockCalled Test-RuleProperties -Exactly 1
            }
        }
        Context 'Ensure is Present and the Firewall Does Exist but has a different RemotePort' {
            It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                Mock Set-NetFirewallRule
                Mock Test-RuleProperties {return $false}
                $result = Set-TargetResource `
                    -Name $FirewallRule.Name `
                    -RemotePort 9999 `
                    -Ensure 'Present'

                Assert-MockCalled Set-NetFirewallRule -Exactly 1
                Assert-MockCalled Test-RuleProperties -Exactly 1
            }
        }
        Context 'Ensure is Present and the Firewall Does Exist but has a different LocalPort' {
            It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                Mock Set-NetFirewallRule
                Mock Test-RuleProperties {return $false}
                $result = Set-TargetResource `
                    -Name $FirewallRule.Name `
                    -LocalPort 9999 `
                    -Ensure 'Present'

                Assert-MockCalled Set-NetFirewallRule -Exactly 1
                Assert-MockCalled Test-RuleProperties -Exactly 1
            }
        }
        Context 'Ensure is Present and the Firewall Does Exist but has a different Protocol' {
            It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                Mock Set-NetFirewallRule
                Mock Test-RuleProperties {return $false}
                if ( $FirewallRule.Protocol -eq 'TCP') {
                    $NewProtocol = 'UDP'
                }
                else
                {
                    $NewProtocol = 'TCP'
                }
                $result = Set-TargetResource `
                    -Name $FirewallRule.Name `
                    -Protocol $NewProtocol `
                    -Ensure 'Present'

                Assert-MockCalled Set-NetFirewallRule -Exactly 1
                Assert-MockCalled Test-RuleProperties -Exactly 1
            }
        }
        Context 'Ensure is Present and the Firewall Does Exist but has a different Description' {
            It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                Mock Set-NetFirewallRule
                Mock Test-RuleProperties {return $false}
                $result = Set-TargetResource `
                    -Name $FirewallRule.Name `
                    -Description 'Different' `
                    -Ensure 'Present'

                Assert-MockCalled Set-NetFirewallRule -Exactly 1
                Assert-MockCalled Test-RuleProperties -Exactly 1
            }
        }
        Context 'Ensure is Present and the Firewall Does Exist but has a different Program' {
            It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                Mock Set-NetFirewallRule
                Mock Test-RuleProperties {return $false}
                $result = Set-TargetResource `
                    -Name $FirewallRule.Name `
                    -Program 'Different' `
                    -Ensure 'Present'

                Assert-MockCalled Set-NetFirewallRule -Exactly 1
                Assert-MockCalled Test-RuleProperties -Exactly 1
            }
        }
        Context 'Ensure is Present and the Firewall Does Exist but has a different Service' {
            It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                Mock Set-NetFirewallRule
                Mock Test-RuleProperties {return $false}
                $result = Set-TargetResource `
                    -Name $FirewallRule.Name `
                    -Service 'Different' `
                    -Ensure 'Present'

                Assert-MockCalled Set-NetFirewallRule -Exactly 1
                Assert-MockCalled Test-RuleProperties -Exactly 1
            }
        }


        Context 'Ensure is Present and the Firewall Does Exist and is the same' {
            It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                Mock Set-NetFirewallRule
                Mock Test-RuleProperties {return $true}
                $result = Set-TargetResource -Name $FirewallRule.Name -Ensure 'Present'

                Assert-MockCalled Set-NetFirewallRule -Exactly 0
                Assert-MockCalled Test-RuleProperties -Exactly 1
            }
        }

    }

######################################################################################

    Describe 'Test-RuleProperties' {
        $FirewallRule = Get-NetFirewallRule | Where-Object {$_.DisplayName -ne $null} |
                    Select-Object -First 1
        $FirewallRule = Get-FirewallRule -Name $FirewallRule.name
        $Properties = Get-FirewallRuleProperty -FirewallRule $FirewallRule

        # Make an object that can be splatted onto the function
        $Splat = @{
            Name = $FirewallRule.Name
            DisplayGroup = $FirewallRule.DisplayGroup
            Group = $FirewallRule.Group
            Enabled = $FirewallRule.Enabled
            Profile = $FirewallRule.Profile.ToString() -replace(' ', '') -split(',')
            Direction = $FirewallRule.Direction
            Action = $FirewallRule.Action
            RemotePort = $Properties.PortFilters.RemotePort
            LocalPort = $Properties.PortFilters.LocalPort
            Protocol = $Properties.PortFilters.Protocol
            Description = $FirewallRule.Description
            Program = $Properties.ApplicationFilters.Program
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
        Context 'testing with a rule with a different displayname' {
            $CompareRule = $Splat.Clone()
            $CompareRule.DisplayName = 'Different'
            It 'should return False' {
                $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different group' {
            $CompareRule = $Splat.Clone()
            $CompareRule.Group = 'Different'
            It 'should return False' {
                $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different enabled' {
            $CompareRule = $Splat.Clone()
            if( $CompareRule.Enabled -eq 'True' ) {
                $CompareRule.Enabled = 'False'
            }
            else
            {
                $CompareRule.Enabled = 'True'
            }
            It 'should return False' {
                $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different action' {
            $CompareRule = $Splat.Clone()
            if ($CompareRule.Action -eq 'Allow') {
                $CompareRule.Action = 'Block'
            }
            else
            {
                $CompareRule.Action = 'Allow'
            }
            It 'should return False' {
                $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different profile' {
            $CompareRule = $Splat.Clone()
            if ( $CompareRule.Profile -ccontains 'Domain') {
                $CompareRule.Profile = @('Public','Private')
            }
            else
            {
                $CompareRule.Profile = @('Domain','Public')
            }
            It 'should return False' {
                $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                $Result | Should be $False
            }
        }
        Context 'testing with a rule with a different direction' {
            $CompareRule = $Splat.Clone()
            if ($CompareRule.Direction -eq 'Inbound') {
                $CompareRule.Direction = 'Outbound'
            }
            else
            {
                $CompareRule.Direction = 'Inbound'
            }
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
            if ( $CompareRule.Protocol -eq 'TCP') {
                $CompareRule.Protocol = 'UDP'
            }
            else
            {
                $CompareRule.Protocol = 'TCP'
            }
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
            $CompareRule.Program = 'Different'
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
        $FirewallRule = Get-NetFirewallRule | Select-Object -First 1
        $FirewallRules = Get-NetFirewallRule | Select-Object -First 2

        Context 'testing with firewall that exists' {
            It 'should return a firewall rule when name is passed' {
                $Result = Get-FirewallRule -Name $FirewallRule.Name
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
            Mock Get-NetFirewallRule -MockWith { $FirewallRules }

            $errorId = 'RuleNotUnique'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
            $errorMessage = $($LocalizedData.RuleNotUniqueError) -f 2,$FirewallRule.Name
            $exception = New-Object -TypeName System.InvalidOperationException `
                -ArgumentList $errorMessage
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                -ArgumentList $exception, $errorId, $errorCategory, $null

            It 'should throw RuleNotUnique exception' {
                { $Result = Get-FirewallRule -Name $FirewallRule.Name } | Should Throw $errorRecord
            }
        }
    }

######################################################################################

    Describe 'Get-FirewallRuleProperty' {
        $FirewallRule = Get-NetFirewallRule | Where-Object {$_.DisplayName -ne $null} |
            Select-Object -First 1

        Context 'All Properties' {
            $result = Get-FirewallRuleProperty -FirewallRule $FirewallRule
            It 'Should return the right address filter' {
                $expected = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $FirewallRule

                $($result.AddressFilters | Out-String -Stream) |
                    Should Be $($expected | Out-String -Stream)
            }

            It 'Should return the right application filter' {
                $expected = Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $FirewallRule

                $($result.ApplicationFilters | Out-String -Stream) |
                    Should Be $($expected | Out-String -Stream)
            }

            It 'Should return the right interface filter' {
                $expected = Get-NetFirewallInterfaceFilter -AssociatedNetFirewallRule $FirewallRule

                $($result.InterfaceFilters | Out-String -Stream) |
                    Should Be $($expected | Out-String -Stream)
            }

            It 'Should return the right interface type filter' {
                $expected = Get-NetFirewallInterfaceTypeFilter -AssociatedNetFirewallRule $FirewallRule
                $($result.InterfaceTypeFilters | Out-String -Stream) |
                    Should Be $($expected | Out-String -Stream)
            }

            It 'Should return the right port filter' {
                $expected = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $FirewallRule
                $($result.PortFilters | Out-String -Stream) |
                    Should Be $($expected | Out-String -Stream)
            }

            It 'Should return the right Profile' {
                $expected = Get-NetFirewallProfile -AssociatedNetFirewallRule $FirewallRule
                $($result.Profile | Out-String -Stream) |
                    Should Be $($expected | Out-String -Stream)
            }

            It 'Should return the right Profile' {
                $expected = Get-NetFirewallProfile -AssociatedNetFirewallRule $FirewallRule
                $($result.Profile | Out-String -Stream) |
                    Should Be $($expected | Out-String -Stream)
            }

            It 'Should return the right Security Filters' {
                $expected = Get-NetFirewallSecurityFilter -AssociatedNetFirewallRule $FirewallRule
                $($result.SecurityFilters | Out-String -Stream) |
                    Should Be $($expected | Out-String -Stream)
            }

            It 'Should return the right Service Filters' {
                $expected = Get-NetFirewallServiceFilter -AssociatedNetFirewallRule $FirewallRule
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
