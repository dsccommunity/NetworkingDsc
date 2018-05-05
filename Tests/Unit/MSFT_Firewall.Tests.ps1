$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_Firewall'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\NetworkingDsc'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $script:DSCResourceName {

        #region Pester Test Initialization
        # Get the rule that will be used for testing
        $firewallRuleName = (Get-NetFirewallRule | `
                Sort-Object Name | `
                Where-Object { $_.DisplayGroup -ne $null } | `
                Select-Object -first 1).Name
        $firewallRule = Get-FirewallRule -Name $firewallRuleName
        $Properties = Get-FirewallRuleProperty -FirewallRule $firewallRule
        # Pull two rules to use testing that error is thrown when this occurs
        $firewallRules = (Get-NetFirewallRule | `
                Sort-Object Name | `
                Where-Object { $_.DisplayGroup -ne $null } | `
                Select-Object -first 2)
        #endregion

        #region Function Get-TargetResource
        Describe 'MSFT_Firewall\Get-TargetResource' {
            Context 'Absent should return correctly' {
                Mock -CommandName Get-NetFirewallRule

                It "Should return absent on firewall rule $($firewallRule.Name)" {
                    $result = Get-TargetResource -Name 'FirewallRule'
                    $result.Name | Should -Be 'FirewallRule'
                    $result.Ensure | Should -Be 'Absent'
                }
            }

            Context 'Present should return correctly' {
                $result = Get-TargetResource -Name $firewallRule.Name

                # Looping these tests
                foreach ($parameter in $ParameterList)
                {
                    if ($parameter.Property)
                    {
                        $parameterValue = (Get-Variable `
                                -Name ($parameter.Variable)).value.$($parameter.Property).$($parameter.Name)
                    }
                    else
                    {
                        $parameterValue = (Get-Variable `
                                -Name ($parameter.Variable)).value.$($parameter.Name)
                    }

                    $parameterNew = (Get-Variable -Name 'Result').Value.$($parameter.Name)

                    It "Should have the correct $($parameter.Name) on firewall rule $($firewallRule.Name)" {
                        if ($parameter.Delimiter)
                        {
                            $parameterNew = $parameterNew -join ','
                        }

                        $parameterNew | Should -Be $parameterValue
                    }
                }
            }
        }
        #endregion

        #region Function Test-TargetResource
        Describe 'MSFT_Firewall\Test-TargetResource' {
            Context 'Ensure is Absent and the Firewall is not Present' {
                Mock -CommandName Get-FirewallRule

                It "Should return $true on firewall rule $($firewallRule.Name)" {
                    $result = Test-TargetResource -Name 'FirewallRule' -Ensure 'Absent'
                    $result | Should -Be $true
                }
            }

            Context 'Ensure is Absent and the Firewall is Present' {
                Mock -CommandName Test-RuleProperties

                It "Should return $false on firewall rule $($firewallRule.Name)" {
                    $result = Test-TargetResource -Name $firewallRule.Name -Ensure 'Absent'
                    $result | Should -Be $false
                }
            }

            Context 'Ensure is Present and the Firewall is Present and properties match' {
                Mock -CommandName Test-RuleProperties -MockWith { return $true }

                It "Should return $true on firewall rule $($firewallRule.Name)" {
                    $result = Test-TargetResource -Name $firewallRule.Name
                    $result | Should -Be $true
                }
            }

            Context 'Ensure is Present and the Firewall is Present and properties are different' {
                Mock -CommandName Test-RuleProperties -MockWith { return $false }

                It "Should return $false on firewall rule $($firewallRule.Name)" {
                    $result = Test-TargetResource -Name $firewallRule.Name
                    $result | Should -Be $false
                }
            }

            Context 'Ensure is Present and the Firewall is Absent' {
                Mock -CommandName Get-FirewallRule
                It "Should return $false on firewall rule $($firewallRule.Name)" {
                    $result = Test-TargetResource -Name $firewallRule.Name
                    $result | Should -Be $false
                }
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe 'MSFT_Firewall\Set-TargetResource' {
            BeforeEach {
                # To speed up all these tests create Mocks so that these functions are not repeatedly called
                Mock -CommandName Get-FirewallRule -MockWith { $firewallRule }
                Mock -CommandName Get-FirewallRuleProperty -MockWith { $Properties }
            }

            Context 'Ensure is Absent and Firewall Exist' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Remove-NetFirewallRule

                    $result = Set-TargetResource -Name $firewallRule.Name -Ensure 'Absent'

                    Assert-MockCalled -CommandName Remove-NetFirewallRule -Exactly -Times 1
                }
            }

            Context 'Ensure is Absent and the Firewall Does Not Exist' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Get-FirewallRule
                    Mock -CommandName Remove-NetFirewallRule

                    $result = Set-TargetResource -Name $firewallRule.Name -Ensure 'Absent'

                    Assert-MockCalled -CommandName Remove-NetFirewallRule -Exactly 0
                }
            }

            Context 'Ensure is Present and the Firewall Does Not Exist' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Get-FirewallRule
                    Mock -CommandName New-NetFirewallRule

                    $result = Set-TargetResource -Name $firewallRule.Name -Ensure 'Present'

                    Assert-MockCalled -CommandName New-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-FirewallRule -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different DisplayName' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -DisplayName 'Different' `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different Group' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName New-NetFirewallRule
                    Mock -CommandName Remove-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -DisplayName $firewallRule.DisplayName `
                        -Group 'Different' `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName New-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Remove-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different Enabled' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    if ( $firewallRule.Enabled -eq 'True' )
                    {
                        $newEnabled = 'False'
                    }
                    else
                    {
                        $newEnabled = 'True'
                    }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -Enabled $newEnabled `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different Action' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    if ( $firewallRule.Action -eq 'Allow')
                    {
                        $NewAction = 'Block'
                    }
                    else
                    {
                        $NewAction = 'Allow'
                    }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -Action $NewAction `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different Profile' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    if ( $firewallRule.Profile -ccontains 'Domain')
                    {
                        $NewProfile = @('Public', 'Private')
                    }
                    else
                    {
                        $NewProfile = @('Domain', 'Public')
                    }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -Profile $NewProfile `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different Direction' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    if ( $firewallRule.Direction -eq 'Inbound')
                    {
                        $NewDirection = 'Outbound'
                    }
                    else
                    {
                        $NewDirection = 'Inbound'
                    }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -Direction $NewDirection `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different RemotePort' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -RemotePort 9999 `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different LocalPort' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -LocalPort 9999 `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different Protocol' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    if ( $firewallRule.Protocol -eq 'TCP')
                    {
                        $NewProtocol = 'UDP'
                    }
                    else
                    {
                        $NewProtocol = 'TCP'
                    }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -Protocol $NewProtocol `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different Description' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -Description 'Different' `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different Program' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -Program 'Different' `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different Service' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -Service 'Different' `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different Authentication' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    if ( $properties.SecurityFilters.Authentication -eq 'Required')
                    {
                        $NewAuthentication = 'NotRequired'
                    }
                    else
                    {
                        $NewAuthentication = 'Required'
                    }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -Authentication $NewAuthentication `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different Encryption' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    if ( $properties.SecurityFilters.Encryption -eq 'Required')
                    {
                        $NewEncryption = 'NotRequired'
                    }
                    else
                    {
                        $NewEncryption = 'Required'
                    }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -Encryption $NewEncryption `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different InterfaceAlias' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -InterfaceAlias 'Different' `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different InterfaceType' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    if ( $properties.InterfaceTypeFilters.InterfaceType -eq 'Wired')
                    {
                        $NewInterfaceType = 'Wireless'
                    }
                    else
                    {
                        $NewInterfaceType = 'Wired'
                    }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -InterfaceType $NewInterfaceType `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different LocalAddress' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -LocalAddress @('10.0.0.1/255.0.0.0', '10.1.1.0-10.1.2.0') `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different LocalUser' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -LocalUser 'Different' `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different Package' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -Package 'Different' `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different Platform' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -Platform @('6.1') `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different RemoteAddress' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -RemoteAddress @('10.0.0.1/255.0.0.0', '10.1.1.0-10.1.2.0') `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different RemoteMachine' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -RemoteMachine 'Different' `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different RemoteUser' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -RemoteUser 'Different' `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different DynamicTransport' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -DynamicTransport 'WifiDirectDisplay' `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different EdgeTraversalPolicy' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -EdgeTraversalPolicy 'Allow' `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different IcmpType' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -IcmpType @('52', '53') `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different LocalOnlyMapping' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -LocalOnlyMapping $true `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different LooseSourceMapping' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -LooseSourceMapping $true `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different OverrideBlockRules' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -OverrideBlockRules $true `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different Owner' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $false }

                    $result = Set-TargetResource `
                        -Name $firewallRule.Name `
                        -Owner (Get-CimInstance win32_useraccount | Select-Object -First 1).Sid `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist and is the same' {
                It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
                    Mock -CommandName Set-NetFirewallRule
                    Mock -CommandName Test-RuleProperties -MockWith { return $true }

                    $result = Set-TargetResource -Name $firewallRule.Name -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly 0
                    Assert-MockCalled -CommandName Test-RuleProperties -Exactly -Times 1
                }
            }
        }
        #endregion

        #region Function Test-RuleProperties
        Describe 'MSFT_Firewall\Test-RuleProperties' {
            # Make an object that can be splatted onto the function
            $Splat = @{}

            foreach ($parameter in $ParameterList)
            {
                if ($parameter.Property)
                {
                    $parameterValue = (Get-Variable `
                            -Name ($parameter.Variable)).value.$($parameter.Property).$($parameter.Name)
                }
                else
                {
                    $parameterValue = (Get-Variable `
                            -Name ($parameter.Variable)).value.$($parameter.Name)
                }

                if ($parameter.Delimiter)
                {
                    $parameterValue = $parameterValue -split $parameter.Delimiter
                }

                $Splat += @{ $parameter.Name = $parameterValue }
            }

            BeforeEach {
                # To speed up all these tests create Mocks so that these functions are not repeatedly called
                Mock -CommandName Get-FirewallRule -MockWith { $firewallRule }
                Mock -CommandName Get-FirewallRuleProperty -MockWith { $Properties }
            }

            Context 'testing with a rule with no property differences' {
                $compareRule = $Splat.Clone()

                It "Should return True on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $true
                }
            }

            Context 'testing with a rule with a different name' {
                $compareRule = $Splat.Clone()
                $compareRule.Name = 'Different'

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different displayname' {
                $compareRule = $Splat.Clone()
                $compareRule.DisplayName = 'Different'

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different group' {
                $compareRule = $Splat.Clone()
                $compareRule.Group = 'Different'

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different enabled' {
                $compareRule = $Splat.Clone()

                if ( $compareRule.Enabled -eq 'True' )
                {
                    $compareRule.Enabled = 'False'
                }
                else
                {
                    $compareRule.Enabled = 'True'
                }

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different action' {
                $compareRule = $Splat.Clone()

                if ($compareRule.Action -eq 'Allow')
                {
                    $compareRule.Action = 'Block'
                }
                else
                {
                    $compareRule.Action = 'Allow'
                }

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different profile' {
                $compareRule = $Splat.Clone()

                if ( $compareRule.Profile -ccontains 'Domain')
                {
                    $compareRule.Profile = @('Public', 'Private')
                }
                else
                {
                    $compareRule.Profile = @('Domain', 'Public')
                }

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different direction' {
                $compareRule = $Splat.Clone()

                if ($compareRule.Direction -eq 'Inbound')
                {
                    $compareRule.Direction = 'Outbound'
                }
                else
                {
                    $compareRule.Direction = 'Inbound'
                }

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different remote port' {
                $compareRule = $Splat.Clone()
                $compareRule.RemotePort = 1

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different local port' {
                $compareRule = $Splat.Clone()
                $compareRule.LocalPort = 1

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different protocol' {
                $compareRule = $Splat.Clone()

                if ( $compareRule.Protocol -eq 'TCP')
                {
                    $compareRule.Protocol = 'UDP'
                }
                else
                {
                    $compareRule.Protocol = 'TCP'
                }

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different description' {
                $compareRule = $Splat.Clone()
                $compareRule.Description = 'Different'

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different program' {
                $compareRule = $Splat.Clone()
                $compareRule.Program = 'Different'

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different service' {
                $compareRule = $Splat.Clone()
                $compareRule.Service = 'Different'

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different Authentication' {
                $compareRule = $Splat.Clone()

                if ( $compareRule.Authentication -eq 'Required')
                {
                    $compareRule.Authentication = 'NotRequired'
                }
                else
                {
                    $compareRule.Authentication = 'Required'
                }

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different Encryption' {
                $compareRule = $Splat.Clone()

                if ( $compareRule.Encryption -eq 'Required')
                {
                    $compareRule.Encryption = 'NotRequired'
                }
                else
                {
                    $compareRule.Encryption = 'Required'
                }

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different InterfaceAlias' {
                $compareRule = $Splat.Clone()
                $compareRule.InterfaceAlias = 'Different'

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different InterfaceType' {
                $compareRule = $Splat.Clone()

                if ( $compareRule.InterfaceType -eq 'Wired')
                {
                    $compareRule.InterfaceType = 'Wireless'
                }
                else
                {
                    $compareRule.InterfaceType = 'Wired'
                }

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different LocalAddress' {
                $compareRule = $Splat.Clone()
                $compareRule.LocalAddress = @('10.0.0.1/255.0.0.0', '10.1.1.0-10.1.2.0')

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different LocalUser' {
                $compareRule = $Splat.Clone()
                $compareRule.LocalUser = 'Different'

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different Package' {
                $compareRule = $Splat.Clone()
                $compareRule.Package = 'Different'

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different Platform' {
                $compareRule = $Splat.Clone()
                $compareRule.Platform = @('6.2')

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different RemoteAddress' {
                $compareRule = $Splat.Clone()
                $compareRule.RemoteAddress = @('10.0.0.1/255.0.0.0', '10.1.1.0-10.1.2.0')

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different RemoteMachine' {
                $compareRule = $Splat.Clone()
                $compareRule.RemoteMachine = 'Different'

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different RemoteUser' {
                $compareRule = $Splat.Clone()
                $compareRule.RemoteUser = 'Different'

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different DynamicTransport' {
                $compareRule = $Splat.Clone()
                $compareRule.DynamicTransport = 'WifiDirectDevices'

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different EdgeTraversalPolicy' {
                $compareRule = $Splat.Clone()
                $compareRule.EdgeTraversalPolicy = 'DeferToApp'

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different IcmpType' {
                $compareRule = $Splat.Clone()
                $compareRule.IcmpType = @('53', '54')

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different LocalOnlyMapping' {
                $compareRule = $Splat.Clone()
                $compareRule.LocalOnlyMapping = ! $compareRule.LocalOnlyMapping

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different LooseSourceMapping' {
                $compareRule = $Splat.Clone()
                $compareRule.LooseSourceMapping = ! $compareRule.LooseSourceMapping

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different OverrideBlockRules' {
                $compareRule = $Splat.Clone()
                $compareRule.OverrideBlockRules = ! $compareRule.OverrideBlockRules

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }

            Context 'testing with a rule with a different Owner' {
                $compareRule = $Splat.Clone()
                $compareRule.Owner = (Get-CimInstance win32_useraccount | Select-Object -First 1).Sid

                It "Should return False on firewall rule $($firewallRule.Name)" {
                    $result = Test-RuleProperties -FirewallRule $firewallRule @compareRule
                    $result | Should -Be $False
                }
            }
        }
        #endregion

        #region Function Get-FirewallRule
        Describe 'MSFT_Firewall\Get-FirewallRule' {
            Context 'testing with firewall that exists' {
                It "Should return a firewall rule when name is passed on firewall rule $($firewallRule.Name)" {
                    $result = Get-FirewallRule -Name $firewallRule.Name
                    $result | Should -Not -BeNullOrEmpty
                }
            }

            Context 'testing with firewall that does not exist' {
                It "Should not return anything on firewall rule $($firewallRule.Name)" {
                    $result = Get-FirewallRule -Name 'Does not exist'
                    $result | Should -BeNullOrEmpty
                }
            }

            Context 'testing with firewall that somehow occurs more than once' {
                Mock -CommandName Get-NetFirewallRule -MockWith { $firewallRules }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.RuleNotUniqueError -f 2, $firewallRule.Name)

                It "Should throw RuleNotUnique exception on firewall rule $($firewallRule.Name)" {
                    { $result = Get-FirewallRule -Name $firewallRule.Name } | Should -Throw $errorRecord
                }
            }
        }
        #endregion


        #region Function Get-FirewallRuleProperty
        Describe "MSFT_Firewall\Get-FirewallRuleProperty" {
            Context 'All Properties' {
                $result = Get-FirewallRuleProperty -FirewallRule $firewallRule

                It "Should return the right address filter on firewall rule $($firewallRule.Name)" {
                    $expected = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $firewallRule

                    $($result.AddressFilters | Out-String -Stream) |
                        Should -Be $($expected | Out-String -Stream)
                }

                It "Should return the right application filter on firewall rule $($firewallRule.Name)" {
                    $expected = Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $firewallRule

                    $($result.ApplicationFilters | Out-String -Stream) |
                        Should -Be $($expected | Out-String -Stream)
                }

                It "Should return the right interface filter on firewall rule $($firewallRule.Name)" {
                    $expected = Get-NetFirewallInterfaceFilter -AssociatedNetFirewallRule $firewallRule

                    $($result.InterfaceFilters | Out-String -Stream) |
                        Should -Be $($expected | Out-String -Stream)
                }

                It "Should return the right interface type filter on firewall rule $($firewallRule.Name)" {
                    $expected = Get-NetFirewallInterfaceTypeFilter -AssociatedNetFirewallRule $firewallRule
                    $($result.InterfaceTypeFilters | Out-String -Stream) |
                        Should -Be $($expected | Out-String -Stream)
                }

                It "Should return the right port filter on firewall rule $($firewallRule.Name)" {
                    $expected = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $firewallRule
                    $($result.PortFilters | Out-String -Stream) |
                        Should -Be $($expected | Out-String -Stream)
                }

                It "Should return the right Profile on firewall rule $($firewallRule.Name)" {
                    $expected = Get-NetFirewallProfile -AssociatedNetFirewallRule $firewallRule
                    $($result.Profile | Out-String -Stream) |
                        Should -Be $($expected | Out-String -Stream)
                }

                It "Should return the right Profile on firewall rule $($firewallRule.Name)" {
                    $expected = Get-NetFirewallProfile -AssociatedNetFirewallRule $firewallRule
                    $($result.Profile | Out-String -Stream) |
                        Should -Be $($expected | Out-String -Stream)
                }

                It "Should return the right Security Filters on firewall rule $($firewallRule.Name)" {
                    $expected = Get-NetFirewallSecurityFilter -AssociatedNetFirewallRule $firewallRule
                    $($result.SecurityFilters | Out-String -Stream) |
                        Should -Be $($expected | Out-String -Stream)
                }

                It "Should return the right Service Filters on firewall rule $($firewallRule.Name)" {
                    $expected = Get-NetFirewallServiceFilter -AssociatedNetFirewallRule $firewallRule
                    $($result.ServiceFilters | Out-String -Stream) |
                        Should -Be $($expected | Out-String -Stream)
                }
            }
        }
        #endregion
    } #end InModuleScope $DSCResourceName
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
