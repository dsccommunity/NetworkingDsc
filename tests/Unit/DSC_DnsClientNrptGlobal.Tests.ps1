# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'NetworkingDsc'
    $script:dscResourceName = 'DSC_DnsClientNrptGlobal'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force
}

Describe 'DSC_DnsClientNrptGlobal\Get-TargetResource' -Tag 'Get' {
    BeforeEach {
        Mock -CommandName Get-DnsClientNrptGlobal -MockWith {
            @{
                EnableDAForAllNetworks  = 'Disable'
                QueryPolicy             = 'Disable'
                SecureNameQueryFallback = 'Disable'
            }
        }
    }

    Context 'DNS Client NRPT Global Settings Exists' {
        It 'Should return correct DNS Client NRPT Global Settings values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetResourceParameters = Get-TargetResource -IsSingleInstance 'Yes'

                $getTargetResourceParameters.EnableDAForAllNetworks | Should -Be 'Disable'
                $getTargetResourceParameters.QueryPolicy | Should -Be 'Disable'
                $getTargetResourceParameters.SecureNameQueryFallback | Should -Be 'Disable'
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-DnsClientNrptGlobal -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_DnsClientNrptGlobal\Set-TargetResource' -Tag 'Set' {
    BeforeEach {
        Mock -CommandName Get-DnsClientNrptGlobal -MockWith {
            @{
                EnableDAForAllNetworks  = 'Disable'
                QueryPolicy             = 'Disable'
                SecureNameQueryFallback = 'Disable'
            }
        }
    }

    Context 'DNS Client NRPT Global Settings all parameters are the same' {
        BeforeAll {
            Mock -CommandName Set-DnsClientNrptGlobal
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    IsSingleInstance        = 'Yes'
                    EnableDAForAllNetworks  = 'Disable'
                    QueryPolicy             = 'Disable'
                    SecureNameQueryFallback = 'Disable'
                }

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-DnsClientNrptGlobal -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-DnsClientNrptGlobal-Exactly -Times 0 -Scope Context
        }
    }

    Context 'DNS Client NRPT Global Settings EnableDAForAllNetworks is different' {
        BeforeAll {
            Mock -CommandName Set-DnsClientNrptGlobal
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    IsSingleInstance        = 'Yes'
                    EnableDAForAllNetworks  = 'Disable'
                    QueryPolicy             = 'Disable'
                    SecureNameQueryFallback = 'Disable'
                }

                $setTargetResourceParameters.EnableDAForAllNetworks = 'EnableAlways'

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-DnsClientNrptGlobal -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-DnsClientNrptGlobal-Exactly -Times 0 -Scope Context
        }
    }


    Context 'DNS Client NRPT Global Settings QueryPolicy is different' {
        BeforeAll {
            Mock -CommandName Set-DnsClientNrptGlobal
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    IsSingleInstance        = 'Yes'
                    EnableDAForAllNetworks  = 'Disable'
                    QueryPolicy             = 'Disable'
                    SecureNameQueryFallback = 'Disable'
                }

                $setTargetResourceParameters.QueryPolicy = 'QueryBoth'

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-DnsClientNrptGlobal -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-DnsClientNrptGlobal-Exactly -Times 0 -Scope Context
        }
    }

    Context 'DNS Client NRPT Global Settings SecureNameQueryFallback is different' {
        BeforeAll {
            Mock -CommandName Set-DnsClientNrptGlobal
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    IsSingleInstance        = 'Yes'
                    EnableDAForAllNetworks  = 'Disable'
                    QueryPolicy             = 'Disable'
                    SecureNameQueryFallback = 'Disable'
                }

                $setTargetResourceParameters.SecureNameQueryFallback = 'FallbackSecure'

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-DnsClientNrptGlobal -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-DnsClientNrptGlobal-Exactly -Times 0 -Scope Context
        }
    }
}

Describe 'DSC_DnsClientNrptGlobal\Test-TargetResource' -Tag 'Test' {
    BeforeEach {
        Mock -CommandName Get-DnsClientNrptGlobal -MockWith {
            @{
                EnableDAForAllNetworks  = 'Disable'
                QueryPolicy             = 'Disable'
                SecureNameQueryFallback = 'Disable'
            }
        }
    }

    Context 'DNS Client NRPT Global Settings configuration' {
        BeforeEach {
            Mock -CommandName Get-DnsClientNrptGlobal -MockWith { $DnsClientNrptGlobal }
        }

        Context 'DNS Client NRPT Global Settings all parameters are the same' {
            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance        = 'Yes'
                        EnableDAForAllNetworks  = 'Disable'
                        QueryPolicy             = 'Disable'
                        SecureNameQueryFallback = 'Disable'
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -BeTrue
                }
            }

            It 'Should call expected Mocks' {
                Should -Invoke -CommandName Get-DnsClientNrptGlobal -Exactly -Times 1 -Scope Context
            }
        }

        Context 'DNS Client NRPT Global Settings EnableDAForAllNetworks is different' {
            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance        = 'Yes'
                        EnableDAForAllNetworks  = 'Disable'
                        QueryPolicy             = 'Disable'
                        SecureNameQueryFallback = 'Disable'
                    }

                    $testTargetResourceParameters.EnableDAForAllNetworks = 'EnableAlways'

                    Test-TargetResource @testTargetResourceParameters | Should -BeFalse
                }
            }

            It 'Should call expected Mocks' {
                Should -Invoke -CommandName Get-DnsClientNrptGlobal -Exactly -Times 1 -Scope Context
            }
        }

        Context 'DNS Client NRPT Global Settings QueryPolicy is different' {
            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance        = 'Yes'
                        EnableDAForAllNetworks  = 'Disable'
                        QueryPolicy             = 'Disable'
                        SecureNameQueryFallback = 'Disable'
                    }

                    $testTargetResourceParameters.QueryPolicy = 'QueryBoth'

                    Test-TargetResource @testTargetResourceParameters | Should -BeFalse
                }
            }

            It 'Should call expected Mocks' {
                Should -Invoke -CommandName Get-DnsClientNrptGlobal -Exactly -Times 1 -Scope Context
            }
        }

        Context 'DNS Client NRPT Global Settings UseDevolution is different' {
            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance        = 'Yes'
                        EnableDAForAllNetworks  = 'Disable'
                        QueryPolicy             = 'Disable'
                        SecureNameQueryFallback = 'Disable'
                    }

                    $testTargetResourceParameters.SecureNameQueryFallback = 'FallbackSecure'

                    Test-TargetResource @testTargetResourceParameters | Should -BeFalse
                }
            }

            It 'Should call expected Mocks' {
                Should -Invoke -CommandName Get-DnsClientNrptGlobal -Exactly -Times 1 -Scope Context
            }
        }
    }
}
