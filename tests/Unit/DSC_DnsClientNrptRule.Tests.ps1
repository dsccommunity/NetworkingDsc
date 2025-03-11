$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_DnsClientNrptRule'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        # Create the Mock Objects that will be used for running tests
        $testNrptRule = [PSObject]@{
            Name        = 'Server'
            Namespace   = '.contoso.com'
            NameServers = ('192.168.1.1')
            Ensure      = 'Present'
        }

        $testNrptRuleKeys = [PSObject]@{
            Name        = $testNrptRule.Name
            Namespace   = $testNrptRule.Namespace
            NameServers = $testNrptRule.NameServers
            NextHop     = $testNrptRule.NextHop
        }

        $mockNrptRule = [PSObject]@{
            Name        = $testNrptRule.Name
            Namespace   = $testNrptRule.Namespace
            NameServers = $testNrptRule.NameServers
            Ensure      = $testNrptRule.Ensure

        }

        Describe 'DSC_DnsClientNrptRule\Get-TargetResource' -Tag 'Get' {
            Context 'NRPT Rule does not exist' {
                Mock -CommandName Get-DnsClientNrptRule

                It 'Should return absent NRPT Rule' {
                    $result = Get-TargetResource @testNrptRuleKeys
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
                }
            }

            Context 'NRPT Rule does exist' {
                Mock -CommandName Get-DnsClientNrptRule -MockWith { $mockNrptRule }

                It 'Should return correct NRPT Rule' {
                    $result = Get-TargetResource @testNrptRuleKeys
                    $result.Ensure | Should -Be 'Present'
                    $result.Namespace | Should -Be $testNrptRule.Namespace
                    $result.NameServers | Should -Be $testNrptRule.NameServers
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
                }
            }
        }

        Describe 'DSC_DnsClientNrptRule\Set-TargetResource' -Tag 'Set' {
            Context 'NRPT Rule does not exist but should' {
                Mock -CommandName Get-DnsClientNrptRule
                Mock -CommandName Add-DnsClientNrptRule
                Mock -CommandName Set-DnsClientNrptRule
                Mock -CommandName Remove-DnsClientNrptRule

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $testNrptRule.Clone()
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Add-DnsClientNrptRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-DnsClientNrptRule -Exactly -Times 0
                    Assert-MockCalled -CommandName Remove-DnsClientNrptRule -Exactly -Times 0
                }
            }

            Context 'NRPT Rule exists and should but has a different Namespace' {
                Mock -CommandName Get-DnsClientNrptRule -MockWith { $mockNrptRule }
                Mock -CommandName Add-DnsClientNrptRule
                Mock -CommandName Set-DnsClientNrptRule
                Mock -CommandName Remove-DnsClientNrptRule

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $testNrptRule.Clone()
                        $setTargetResourceParameters.Namespace = '.fabrikam.com'
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Add-DnsClientNrptRule -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-DnsClientNrptRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Remove-DnsClientNrptRule -Exactly -Times 0
                }
            }

            Context 'NRPT Rule exists and should but has a different NameServers' {
                Mock -CommandName Get-DnsClientNrptRule-MockWith { $mockNrptRule }
                Mock -CommandName Add-DnsClientNrptRule
                Mock -CommandName Set-DnsClientNrptRule
                Mock -CommandName Remove-DnsClientNrptRule

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $testNrptRule.Clone()
                        $setTargetResourceParameters.NameServers = ('192.168.0.1')
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Add-DnsClientNrptRule -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-DnsClientNrptRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Remove-DnsClientNrptRule -Exactly -Times 0
                }
            }


            Context 'NRPT Rule exists and but should not' {
                Mock -CommandName Get-DnsClientNrptRule -MockWith { $mockNrptRule }
                Mock -CommandName Add-DnsClientNrptRule
                Mock -CommandName Set-DnsClientNrptRule
                Mock -CommandName Remove-DnsClientNrptRule `
                    -ParameterFilter {
                    ($Namespace -eq $testNrptRule.Namespace) -and `
                    ($NameServers -eq $testNrptRule.NameServers)
                }

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $testNrptRule.Clone()
                        $setTargetResourceParameters.Ensure = 'Absent'
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected mocks and parameters' {
                    Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Add-DnsClientNrptRule -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-DnsClientNrptRule -Exactly -Times 0
                    Assert-MockCalled -CommandName Remove-DnsClientNrptRule `
                        -ParameterFilter {
                            ($Namespace -eq $testNrptRule.Namespace) -and `
                            ($NameServers -eq $testNrptRule.NameServers)
                    } `
                        -Exactly -Times 1
                }
            }

            Context 'NRPT Rule does not exist and should not' {
                Mock -CommandName Get-DnsClientNrptRule
                Mock -CommandName Add-DnsClientNrptRule
                Mock -CommandName Set-DnsClientNrptRule
                Mock -CommandName Remove-DnsClientNrptRule

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $testNrptRule.Clone()
                        $setTargetResourceParameters.Ensure = 'Absent'
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
                    Assert-MockCalled -CommandName Add-DnsClientNrptRule -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-DnsClientNrptRule -Exactly -Times 0
                    Assert-MockCalled -CommandName Remove-DnsClientNrptRule -Exactly -Times 0
                }
            }
        }

        Describe 'DSC_DnsClientNrptRule\Test-TargetResource' -Tag 'Test' {
            Context 'NRPT Rule does not exist but should' {
                Mock -CommandName Get-DnsClientNrptRule

                It 'Should return false' {
                    $testTargetResourceParameters = $testNrptRule.Clone()
                    Test-TargetResource @testTargetResourceParameters | Should -Be $False

                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
                }
            }

            Context 'NRPT Rule exists and should but has a different Namespace' {
                Mock -CommandName Get-DnsClientNrptRule -MockWith { $mockNrptRule }

                It 'Should return false' {
                    {
                        $testTargetResourceParameters = $testNrptRule.Clone()
                        $testTargetResourceParameters.Namespace = '.fabrikam.com'
                        Test-TargetResource @testTargetResourceParameters | Should -Be $False
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
                }
            }

            Context 'NRPT Rule exists and should but has a different NameServers' {
                Mock -CommandName Get-DnsClientNrptRule -MockWith { $mockNrptRule }

                It 'Should return false' {
                    {
                        $testTargetResourceParameters = $testNrptRule.Clone()
                        $testTargetResourceParameters.NameServers = ('192.168.0.1')
                        Test-TargetResource @testTargetResourceParameters | Should -Be $False
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
                }
            }

            Context 'NRPT Rule exists and should and all parameters match' {
                Mock -CommandName Get-DnsClientNrptRule -MockWith { $mockNrptRule }

                It 'Should return true' {
                    {
                        $testTargetResourceParameters = $testNrptRule.Clone()
                        Test-TargetResource @testTargetResourceParameters | Should -Be $True
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
                }
            }

            Context 'NRPT Rule exists but should not' {
                Mock -CommandName Get-DnsClientNrptRule -MockWith { $mockNrptRule }

                It 'Should return false' {
                    {
                        $testTargetResourceParameters = $testNrptRule.Clone()
                        $testTargetResourceParameters.Ensure = 'Absent'
                        Test-TargetResource @testTargetResourceParameters | Should -Be $False
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
                }
            }

            Context 'NRPT Rule does not exist and should not' {
                Mock -CommandName Get-DnsClientNrptRule

                It 'Should return true' {
                    {
                        $testTargetResourceParameters = $testNrptRule.Clone()
                        $testTargetResourceParameters.Ensure = 'Absent'
                        Test-TargetResource @testTargetResourceParameters | Should -Be $True
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
