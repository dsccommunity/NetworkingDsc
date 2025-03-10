$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_DnsClientNrptGlobal'

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
        $DnsClientNrptGlobal = [PSObject] @{
            EnableDAForAllNetworks  = 'Disable'
            QueryPolicy             = 'Disable'
            SecureNameQueryFallback = 'Disable'
        }

        $DnsClientNrptGlobalSplat = [PSObject]@{
            IsSingleInstance = 'Yes'
            EnableDAForAllNetworks  = $DnsClientNrptGlobal.EnableDAForAllNetworks
            QueryPolicy             = $DnsClientNrptGlobal.QueryPolicy
            SecureNameQueryFallback = $DnsClientNrptGlobal.SecureNameQueryFallback
        }

        Describe 'DSC_DnsClientNrptGlobal\Get-TargetResource' -Tag 'Get' {
            BeforeEach {
                Mock -CommandName Get-DnsClientNrptGlobal -MockWith { $DnsClientNrptGlobal }
            }

            Context 'DNS Client NRPT Global Settings Exists' {
                It 'Should return correct DNS Client NRPT Global Settings values' {
                    $getTargetResourceParameters = Get-TargetResource -IsSingleInstance 'Yes'
                    $getTargetResourceParameters.EnableDAForAllNetworks | Should -Be $DnsClientNrptGlobal.EnableDAForAllNetworks
                    $getTargetResourceParameters.QueryPolicy | Should -Be $DnsClientNrptGlobal.QueryPolicy
                    $getTargetResourceParameters.SecureNameQueryFallback | Should -Be $DnsClientNrptGlobal.SecureNameQueryFallback
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-DnsClientNrptGlobal -Exactly -Times 1
                }
            }
        }

        Describe 'DSC_DnsClientNrptGlobal\Set-TargetResource' -Tag 'Set' {
            BeforeEach {
                Mock -CommandName Get-DnsClientNrptGlobal -MockWith { $DnsClientNrptGlobal }
            }

            Context 'DNS Client NRPT Global Settings all parameters are the same' {
                Mock -CommandName Set-DnsClientNrptGlobal

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $DnsClientNrptGlobalSplat.Clone()
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DnsClientNrptGlobal -Exactly -Times 1
                    Assert-MockCalled -commandName Set-DnsClientNrptGlobal -Exactly -Times 0
                }
            }

            Context 'DNS Client NRPT Global Settings EnableDAForAllNetworks is different' {
                Mock -CommandName Set-DnsClientNrptGlobal

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $DnsClientNrptGlobalSplat.Clone()
                        $setTargetResourceParameters.EnableDAForAllNetworks = 'EnableAlways'
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DnsClientNrptGlobal -Exactly -Times 1
                    Assert-MockCalled -commandName Set-DnsClientNrptGlobal -Exactly -Times 1
                }
            }


            Context 'DNS Client NRPT Global Settings QueryPolicy is different' {
                Mock -CommandName Set-DnsClientNrptGlobal

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $DnsClientNrptGlobalSplat.Clone()
                        $setTargetResourceParameters.QueryPolicy = 'QueryBoth'
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DnsClientNrptGlobal -Exactly -Times 1
                    Assert-MockCalled -commandName Set-DnsClientNrptGlobal -Exactly -Times 1
                }
            }

            Context 'DNS Client NRPT Global Settings SecureNameQueryFallback is different' {
                Mock -CommandName Set-DnsClientNrptGlobal

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $DnsClientNrptGlobalSplat.Clone()
                        $setTargetResourceParameters.SecureNameQueryFallback = 'FallbackSecure'
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DnsClientNrptGlobal -Exactly -Times 1
                    Assert-MockCalled -commandName Set-DnsClientNrptGlobal -Exactly -Times 1
                }
            }
        }

        Describe 'DSC_DnsClientNrptGlobal\Test-TargetResource' -Tag 'Test' {
            Context 'DNS Client NRPT Global Settings configuration' {
                BeforeEach {
                    Mock -CommandName Get-DnsClientNrptGlobal -MockWith { $DnsClientNrptGlobal }
                }

                Context 'DNS Client NRPT Global Settings all parameters are the same' {
                    It 'Should return true' {
                        $testTargetResourceParameters = $DnsClientNrptGlobalSplat.Clone()
                        Test-TargetResource @testTargetResourceParameters | Should -Be $true
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-DnsClientNrptGlobal -Exactly -Times 1
                    }
                }

                Context 'DNS Client NRPT Global Settings EnableDAForAllNetworks is different' {
                    It 'Should return false' {
                        $testTargetResourceParameters = $DnsClientNrptGlobalSplat.Clone()
                        $testTargetResourceParameters.EnableDAForAllNetworks = 'EnableAlways'
                        Test-TargetResource @testTargetResourceParameters | Should -Be $False
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-DnsClientNrptGlobal -Exactly -Times 1
                    }
                }

                Context 'DNS Client NRPT Global Settings QueryPolicy is different' {
                    It 'Should return false' {
                        $testTargetResourceParameters = $DnsClientNrptGlobalSplat.Clone()
                        $testTargetResourceParameters.QueryPolicy = 'QueryBoth'
                        Test-TargetResource @testTargetResourceParameters | Should -Be $False
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-DnsClientNrptGlobal -Exactly -Times 1
                    }
                }

                Context 'DNS Client NRPT Global Settings UseDevolution is different' {
                    It 'Should return false' {
                        $testTargetResourceParameters = $DnsClientNrptGlobalSplat.Clone()
                        $testTargetResourceParameters.SecureNameQueryFallback = 'FallbackSecure'
                        Test-TargetResource @testTargetResourceParameters | Should -Be $False
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-DnsClientNrptGlobal -Exactly -Times 1
                    }
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
