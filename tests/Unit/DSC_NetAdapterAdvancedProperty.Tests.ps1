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
    $script:dscResourceName = 'DSC_NetAdapterAdvancedProperty'

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

Describe 'DSC_NetAdapterAdvancedProperty\Get-TargetResource' -Tag 'Get' {
    Context 'Adapter exist and JumboPacket is enabled 9014' {
        BeforeAll {
            Mock Get-NetAdapterAdvancedProperty -Verbose -MockWith {
                @{
                    RegistryValue   = 9014
                    RegistryKeyword = '*JumboPacket'
                }
            }
        }

        It 'Should return the JumboPacket size' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    NetworkAdapterName = 'Ethernet'
                    RegistryKeyword    = '*JumboPacket'
                    RegistryValue      = 9014
                }

                $result = Get-TargetResource @testParams
                $result.RegistryValue | Should -Be $testParams.RegistryValue
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterAdvancedProperty -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter exist and JumboPacket is 1514' {
        BeforeAll {
            Mock Get-NetAdapterAdvancedProperty -Verbose -MockWith {
                @{
                    RegistryValue   = 1514
                    RegistryKeyword = '*JumboPacket'
                }
            }
        }

        It 'Should return the JumboPacket size' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    NetworkAdapterName = 'Ethernet'
                    RegistryKeyword    = '*JumboPacket'
                    RegistryValue      = 1514
                }

                $result = Get-TargetResource @testParams
                $result.RegistryValue | Should -Be $testParams.RegistryValue
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterAdvancedProperty -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterAdvancedProperty -MockWith { throw 'Network adapter not found' }
        }


        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundMessage)

                $testParams = @{
                    NetworkAdapterName = 'Ethe'
                    RegistryKeyword    = '*JumboPacket'
                    RegistryValue      = 1514
                }

                { Get-TargetResource @testParams } | Should -Throw $errorRecord
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterAdvancedProperty -Exactly -Time 1 -Scope Context
        }
    }

    Describe 'DSC_NetAdapterAdvancedProperty\Set-TargetResource' -Tag 'Set' {
        Context 'Adapter exist, JumboPacket is 9014, no action required' {
            BeforeAll {
                Mock -CommandName Get-NetAdapterAdvancedProperty -MockWith {
                    @{
                        RegistryValue   = 9014
                        RegistryKeyword = '*JumboPacket'
                    }
                }
                Mock -CommandName Set-NetAdapterAdvancedProperty
            }

            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        NetworkAdapterName = 'Ethernet'
                        RegistryKeyword    = '*JumboPacket'
                        RegistryValue      = 9014
                    }

                    { Set-TargetResource @testParams } | Should -Not -Throw
                }
            }

            It 'Should call all mocks' {
                Should -Invoke -CommandName Get-NetAdapterAdvancedProperty -Exactly -Time 1 -Scope Context
                Should -Invoke -CommandName Set-NetAdapterAdvancedProperty -Exactly -Time 0 -Scope Context
            }
        }

        Context 'Adapter exist, JumboPacket is 9014, should be 1514' {
            BeforeAll {
                Mock -CommandName Get-NetAdapterAdvancedProperty -MockWith {
                    @{
                        RegistryValue   = 9014
                        RegistryKeyword = '*JumboPacket'
                    }
                }

                Mock -CommandName Set-NetAdapterAdvancedProperty
            }

            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        NetworkAdapterName = 'Ethernet'
                        RegistryKeyword    = '*JumboPacket'
                        RegistryValue      = 1514
                    }

                    { Set-TargetResource @testParams } | Should -Not -Throw
                }
            }

            It 'Should call all mocks' {
                Should -Invoke -CommandName Get-NetAdapterAdvancedProperty -Exactly -Time 1 -Scope Context
                Should -Invoke -CommandName Set-NetAdapterAdvancedProperty -Exactly -Time 1 -Scope Context
            }
        }

        Context 'Adapter exist, JumboPacket is 1514, should be 9014' {
            BeforeAll {
                Mock -CommandName Get-NetAdapterAdvancedProperty -MockWith {
                    @{
                        RegistryValue   = 1514
                        RegistryKeyword = '*JumboPacket'
                    }
                }

                Mock -CommandName Set-NetAdapterAdvancedProperty
            }

            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        NetworkAdapterName = 'Ethernet'
                        RegistryKeyword    = '*JumboPacket'
                        RegistryValue      = 9014
                    }

                    { Set-TargetResource @testParams } | Should -Not -Throw
                }
            }

            It 'Should call all mocks' {
                Should -Invoke -CommandName Get-NetAdapterAdvancedProperty -Exactly -Time 1 -Scope Context
                Should -Invoke -CommandName Set-NetAdapterAdvancedProperty -Exactly -Time 1 -Scope Context
            }
        }

        # Adapter
        Context 'Adapter does not exist' {
            BeforeAll {
                Mock -CommandName Get-NetAdapterAdvancedProperty -MockWith { throw 'Network adapter not found' }
            }

            It 'Should throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.NetAdapterNotFoundMessage)

                    $testParams = @{
                        NetworkAdapterName = 'Ethe'
                        RegistryKeyword    = '*JumboPacket'
                        RegistryValue      = 1514
                    }

                    { Set-TargetResource @testParams } | Should -Throw $errorRecord
                }
            }

            It 'Should call all mocks' {
                Should -Invoke -CommandName Get-NetAdapterAdvancedProperty -Exactly -Time 1 -Scope Context
            }
        }
    }
}

Describe 'DSC_NetAdapterAdvancedProperty\Test-TargetResource' -Tag 'Test' {
    Context 'Adapter exist, JumboPacket is 9014, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterAdvancedProperty -MockWith {
                @{
                    RegistryValue   = 9014
                    RegistryKeyword = '*JumboPacket'
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    NetworkAdapterName = 'Ethernet'
                    RegistryKeyword    = '*JumboPacket'
                    RegistryValue      = 9014
                }

                Test-TargetResource @testParams | Should -BeTrue
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterAdvancedProperty -Exactly 1 -Scope Context
        }
    }

    Context 'Adapter exist, JumboPacket is 9014 should be 1514' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterAdvancedProperty -MockWith {
                @{
                    RegistryValue   = 9014
                    RegistryKeyword = '*JumboPacket'
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    NetworkAdapterName = 'Ethernet'
                    RegistryKeyword    = '*JumboPacket'
                    RegistryValue      = 1514
                }

                Test-TargetResource @testParams | Should -BeFalse
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterAdvancedProperty -Exactly 1 -Scope Context
        }
    }


    # Adapter
    Context 'Adapter does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterAdvancedProperty -MockWith { throw 'Network adapter not found' }
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    NetworkAdapterName = 'Ethe'
                    RegistryKeyword    = '*JumboPacket'
                    RegistryValue      = 1514
                }

                { Test-TargetResource @testParams } | Should -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterAdvancedProperty -Exactly 1 -Scope Context
        }
    }
}
