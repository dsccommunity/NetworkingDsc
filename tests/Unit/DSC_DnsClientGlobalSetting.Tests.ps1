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
    $script:dscResourceName = 'DSC_DnsClientGlobalSetting'

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

Describe 'DSC_DnsClientGlobalSetting\Get-TargetResource' -Tag 'Get' {
    BeforeEach {
        Mock -CommandName Get-DnsClientGlobalSetting -MockWith {
            @{
                SuffixSearchList = 'contoso.com'
                DevolutionLevel  = 1
                UseDevolution    = $true
            }
        }
    }

    Context 'DNS Client Global Settings Exists' {
        It 'Should return correct DNS Client Global Settings values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetResourceParameters = Get-TargetResource -IsSingleInstance 'Yes'

                $getTargetResourceParameters.SuffixSearchList | Should -Be 'contoso.com'
                $getTargetResourceParameters.DevolutionLevel | Should -Be 1
                $getTargetResourceParameters.UseDevolution | Should -BeTrue
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-DnsClientGlobalSetting -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_DnsClientGlobalSetting\Set-TargetResource' -Tag 'Set' {
    BeforeEach {
        Mock -CommandName Get-DnsClientGlobalSetting -MockWith {
            @{
                SuffixSearchList = 'contoso.com'
                DevolutionLevel  = 1
                UseDevolution    = $true
            }
        }
    }

    Context 'DNS Client Global Settings all parameters are the same' {
        BeforeAll {
            Mock -CommandName Set-DnsClientGlobalSetting
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    IsSingleInstance = 'Yes'
                    SuffixSearchList = 'contoso.com'
                    DevolutionLevel  = 1
                    UseDevolution    = $true
                }

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-DnsClientGlobalSetting -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-DnsClientGlobalSetting -Exactly -Times 0 -Scope Context
        }
    }

    Context 'DNS Client Global Settings SuffixSearchList is different' {
        BeforeAll {
            Mock -CommandName Set-DnsClientGlobalSetting
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    IsSingleInstance = 'Yes'
                    SuffixSearchList = 'contoso.com'
                    DevolutionLevel  = 1
                    UseDevolution    = $true
                }

                $setTargetResourceParameters.SuffixSearchList = 'fabrikam.com'

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-DnsClientGlobalSetting -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-DnsClientGlobalSetting -Exactly -Times 1 -Scope Context
        }
    }

    Context 'DNS Client Global Settings SuffixSearchList Array is different' {
        BeforeAll {
            $suffixSearchListArray = @('fabrikam.com', 'fourthcoffee.com')

            $setDnsClientGlobalMockParameterFilter = {
                    (Compare-Object -ReferenceObject $suffixSearchList -DifferenceObject $suffixSearchListArray -SyncWindow 0).Length -eq 0
            }

            Mock -CommandName Set-DnsClientGlobalSetting -ParameterFilter $setDnsClientGlobalMockParameterFilter
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    IsSingleInstance = 'Yes'
                    SuffixSearchList = 'contoso.com'
                    DevolutionLevel  = 1
                    UseDevolution    = $true
                }

                $setTargetResourceParameters.SuffixSearchList = @('fabrikam.com', 'fourthcoffee.com')

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-DnsClientGlobalSetting -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-DnsClientGlobalSetting -ParameterFilter $setDnsClientGlobalMockParameterFilter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'DNS Client Global Settings DevolutionLevel is different' {
        BeforeAll {
            Mock -CommandName Set-DnsClientGlobalSetting
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    IsSingleInstance = 'Yes'
                    SuffixSearchList = 'contoso.com'
                    DevolutionLevel  = 1
                    UseDevolution    = $true
                }

                $setTargetResourceParameters.DevolutionLevel = $setTargetResourceParameters.DevolutionLevel + 1

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-DnsClientGlobalSetting -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-DnsClientGlobalSetting -Exactly -Times 1 -Scope Context
        }
    }

    Context 'DNS Client Global Settings UseDevolution is different' {
        BeforeAll {
            Mock -CommandName Set-DnsClientGlobalSetting
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    IsSingleInstance = 'Yes'
                    SuffixSearchList = 'contoso.com'
                    DevolutionLevel  = 1
                    UseDevolution    = $true
                }

                $setTargetResourceParameters.UseDevolution = -not $setTargetResourceParameters.UseDevolution

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-DnsClientGlobalSetting -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-DnsClientGlobalSetting -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_DnsClientGlobalSetting\Test-TargetResource' -Tag 'Test' {
    Context 'Single suffix is in the search list' {
        BeforeEach {
            Mock -CommandName Get-DnsClientGlobalSetting -MockWith {
                @{
                    SuffixSearchList = 'contoso.com'
                    DevolutionLevel  = 1
                    UseDevolution    = $true
                }
            }
        }

        Context 'DNS Client Global Settings all parameters are the same' {
            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance = 'Yes'
                        SuffixSearchList = 'contoso.com'
                        DevolutionLevel  = 1
                        UseDevolution    = $true
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -BeTrue
                }
            }

            It 'Should call expected Mocks' {
                Should -Invoke -CommandName Get-DnsClientGlobalSetting -Exactly -Times 1 -Scope Context
            }
        }

        Context 'DNS Client Global Settings SuffixSearchList is different' {
            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance = 'Yes'
                        SuffixSearchList = 'contoso.com'
                        DevolutionLevel  = 1
                        UseDevolution    = $true
                    }

                    $testTargetResourceParameters.SuffixSearchList = 'fabrikam.com'

                    Test-TargetResource @testTargetResourceParameters | Should -BeFalse
                }
            }

            It 'Should call expected Mocks' {
                Should -Invoke -CommandName Get-DnsClientGlobalSetting -Exactly -Times 1 -Scope Context
            }
        }

        Context 'DNS Client Global Settings DevolutionLevel is different' {
            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance = 'Yes'
                        SuffixSearchList = 'contoso.com'
                        DevolutionLevel  = 1
                        UseDevolution    = $true
                    }

                    $testTargetResourceParameters.DevolutionLevel = $testTargetResourceParameters.DevolutionLevel + 1

                    Test-TargetResource @testTargetResourceParameters | Should -BeFalse
                }
            }

            It 'Should call expected Mocks' {
                Should -Invoke -CommandName Get-DnsClientGlobalSetting -Exactly -Times 1 -Scope Context
            }
        }

        Context 'DNS Client Global Settings UseDevolution is different' {
            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance = 'Yes'
                        SuffixSearchList = 'contoso.com'
                        DevolutionLevel  = 1
                        UseDevolution    = $true
                    }

                    $testTargetResourceParameters.UseDevolution = -not $testTargetResourceParameters.UseDevolution

                    Test-TargetResource @testTargetResourceParameters | Should -BeFalse
                }
            }

            It 'Should call expected Mocks' {
                Should -Invoke -CommandName Get-DnsClientGlobalSetting -Exactly -Times 1 -Scope Context
            }
        }
    }

    Context 'Mulitple suffixes are in the search list' {
        BeforeEach {
            Mock -CommandName Get-DnsClientGlobalSetting -MockWith {
                @{
                    SuffixSearchList = @('fabrikam.com', 'fourthcoffee.com')
                    DevolutionLevel  = 1
                    UseDevolution    = $true
                }
            }
        }

        Context 'DNS Client Global Settings SuffixSearchList Array is different' {
            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance = 'Yes'
                        SuffixSearchList = 'contoso.com'
                        DevolutionLevel  = 1
                        UseDevolution    = $true
                    }

                    $testTargetResourceParameters.SuffixSearchList = @('fabrikam.com', 'contoso.com')

                    Test-TargetResource @testTargetResourceParameters | Should -BeFalse
                }
            }

            It 'Should call expected Mocks' {
                Should -Invoke -CommandName Get-DnsClientGlobalSetting -Exactly -Times 1 -Scope Context
            }
        }

        Context 'DNS Client Global Settings SuffixSearchList Array Order is same' {
            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance = 'Yes'
                        SuffixSearchList = 'contoso.com'
                        DevolutionLevel  = 1
                        UseDevolution    = $true
                    }

                    $testTargetResourceParameters.SuffixSearchList = @('fabrikam.com', 'fourthcoffee.com')

                    Test-TargetResource @testTargetResourceParameters | Should -BeTrue
                }
            }

            It 'Should call expected Mocks' {
                Should -Invoke -CommandName Get-DnsClientGlobalSetting -Exactly -Times 1 -Scope Context
            }
        }

        Context 'DNS Client Global Settings SuffixSearchList Array Order is different' {
            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance = 'Yes'
                        SuffixSearchList = 'contoso.com'
                        DevolutionLevel  = 1
                        UseDevolution    = $true
                    }

                    $testTargetResourceParameters.SuffixSearchList = @('fourthcoffee.com', 'fabrikam.com')

                    Test-TargetResource @testTargetResourceParameters | Should -BeFalse
                }
            }

            It 'Should call expected Mocks' {
                Should -Invoke -CommandName Get-DnsClientGlobalSetting -Exactly -Times 1 -Scope Context
            }
        }
    }

    Context 'When the search list is an empty array' {
        BeforeEach {
            Mock -CommandName Get-DnsClientGlobalSetting -MockWith {
                @{
                    SuffixSearchList = @()
                    DevolutionLevel  = 1
                    UseDevolution    = $true
                }
            }
        }

        Context 'When the DNS Client Global Settings SuffixSearchList Array is different' {
            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance = 'Yes'
                        SuffixSearchList = 'contoso.com'
                        DevolutionLevel  = 1
                        UseDevolution    = $true
                    }

                    $testTargetResourceParameters.SuffixSearchList = @('fabrikam.com')

                    Test-TargetResource @testTargetResourceParameters | Should -BeFalse
                }
            }

            It 'Should call expected Mocks' {
                Should -Invoke -CommandName Get-DnsClientGlobalSetting -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When the DNS Client Global Settings SuffixSearchList is same' {
            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance = 'Yes'
                        SuffixSearchList = 'contoso.com'
                        DevolutionLevel  = 1
                        UseDevolution    = $true
                    }

                    $testTargetResourceParameters.SuffixSearchList = @()

                    Test-TargetResource @testTargetResourceParameters | Should -BeTrue
                }
            }

            It 'Should call expected Mocks' {
                Should -Invoke -CommandName Get-DnsClientGlobalSetting -Exactly -Times 1 -Scope Context
            }
        }
    }

    Context 'When the search list is an empty string' {
        BeforeEach {
            Mock -CommandName Get-DnsClientGlobalSetting -MockWith {
                @{
                    SuffixSearchList = ''
                    DevolutionLevel  = 1
                    UseDevolution    = $true
                }
            }
        }

        Context 'When the DNS Client Global Settings SuffixSearchList Array is different' {
            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance = 'Yes'
                        SuffixSearchList = 'contoso.com'
                        DevolutionLevel  = 1
                        UseDevolution    = $true
                    }

                    $testTargetResourceParameters.SuffixSearchList = @('fabrikam.com')

                    Test-TargetResource @testTargetResourceParameters | Should -BeFalse
                }
            }

            It 'Should call expected Mocks' {
                Should -Invoke -CommandName Get-DnsClientGlobalSetting -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When the DNS Client Global Settings SuffixSearchList is same' {
            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance = 'Yes'
                        SuffixSearchList = 'contoso.com'
                        DevolutionLevel  = 1
                        UseDevolution    = $true
                    }

                    $testTargetResourceParameters.SuffixSearchList = @()

                    Test-TargetResource @testTargetResourceParameters | Should -BeTrue
                }
            }

            It 'Should call expected Mocks' {
                Should -Invoke -CommandName Get-DnsClientGlobalSetting -Exactly -Times 1 -Scope Context
            }
        }
    }
}
