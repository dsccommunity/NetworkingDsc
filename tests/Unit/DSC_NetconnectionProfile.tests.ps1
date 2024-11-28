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
    $script:dscResourceName = 'DSC_NetConnectionProfile'

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

Describe 'DSC_NetConnectionProfile\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        Mock -CommandName Get-NetConnectionProfile {
            @{
                InterfaceAlias   = 'TestAdapter'
                NetworkCategory  = 'Public'
                IPv4Connectivity = 'Internet'
                IPv6Connectivity = 'Internet'
            }
        }
    }

    It 'Should return the correct values' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $mockNetConnectionProfileAll = @{
                InterfaceAlias   = 'TestAdapter'
                NetworkCategory  = 'Public'
                IPv4Connectivity = 'Internet'
                IPv6Connectivity = 'Internet'
            }

            $result = Get-TargetResource -InterfaceAlias 'TestAdapter'
            $result.InterfaceAlias | Should -Be $mockNetConnectionProfileAll.InterfaceAlias
            $result.NetworkCategory | Should -Be $mockNetConnectionProfileAll.NetworkCategory
            $result.IPv4Connectivity | Should -Be $mockNetConnectionProfileAll.IPv4Connectivity
            $result.IPv6Connectivity | Should -Be $mockNetConnectionProfileAll.IPv6Connectivity
        }
    }
}

Describe 'DSC_NetConnectionProfile\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        Mock -CommandName Get-TargetResource -MockWith {
            @{
                InterfaceAlias   = 'TestAdapter'
                NetworkCategory  = 'Public'
                IPv4Connectivity = 'Internet'
                IPv6Connectivity = 'Internet'
            }
        }

        Mock -CommandName Assert-ResourceProperty
    }

    Context 'NetworkCategory matches' {
        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testNetworkCategoryMatches = @{
                    InterfaceAlias  = 'TestAdapter'
                    NetworkCategory = 'Public'
                }

                Test-TargetResource @testNetworkCategoryMatches | Should -BeTrue
            }
        }
    }

    Context 'NetworkCategory does not match' {
        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testNetworkCategoryNoMatches = @{
                    InterfaceAlias  = 'TestAdapter'
                    NetworkCategory = 'Private'
                }

                Test-TargetResource @testNetworkCategoryNoMatches | Should -BeFalse
            }
        }
    }

    Context 'IPv4Connectivity matches' {
        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv4ConnectivityMatches = @{
                    InterfaceAlias   = 'TestAdapter'
                    IPv4Connectivity = 'Internet'
                }

                Test-TargetResource @testIPv4ConnectivityMatches | Should -BeTrue
            }
        }
    }

    Context 'IPv4Connectivity does not match' {
        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv4ConnectivityNoMatches = @{
                    InterfaceAlias   = 'TestAdapter'
                    IPv4Connectivity = 'Disconnected'
                }

                Test-TargetResource @testIPv4ConnectivityNoMatches | Should -BeFalse
            }
        }
    }

    Context 'IPv6Connectivity matches' {
        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv6ConnectivityMatches = @{
                    InterfaceAlias   = 'TestAdapter'
                    IPv6Connectivity = 'Internet'
                }

                Test-TargetResource @testIPv6ConnectivityMatches | Should -BeTrue
            }
        }
    }

    Context 'IPv6Connectivity does not match' {
        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv6ConnectivityNoMatches = @{
                    InterfaceAlias   = 'TestAdapter'
                    IPv6Connectivity = 'Disconnected'
                }

                Test-TargetResource @testIPv6ConnectivityNoMatches | Should -BeFalse
            }
        }
    }
}

Describe 'DSC_NetConnectionProfile\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Set-NetConnectionProfile
        Mock -CommandName Assert-ResourceProperty
    }

    It 'Should call all the mocks' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $testNetworkCategoryMatches = @{
                InterfaceAlias  = 'TestAdapter'
                NetworkCategory = 'Public'
            }

            Set-TargetResource @testNetworkCategoryMatches
        }

        Should -Invoke -CommandName Set-NetConnectionProfile
    }
}

Describe 'DSC_NetConnectionProfile\Assert-ResourceProperty' {
    Context 'Invoking with bad interface alias' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter
        }

        It 'Should throw testValidInterfaceAliasOnlyPassed exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testValidInterfaceAliasOnlyPassed = @{
                    InterfaceAlias = 'TestAdapter'
                }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.InterfaceNotAvailableError -f $testValidInterfaceAliasOnlyPassed.InterfaceAlias)


                { Assert-ResourceProperty @testValidInterfaceAliasOnlyPassed } | Should -Throw $errorRecord
            }
        }
    }

    Context 'Invoking with valid interface alias but all empty parameters' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name = 'TestAdapter'
                }
            }
        }

        It 'Should not ParameterCombinationError exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.ParameterCombinationError)

                $testValidInterfaceAliasOnlyPassed = @{
                    InterfaceAlias = 'TestAdapter'
                }

                { Assert-ResourceProperty @testValidInterfaceAliasOnlyPassed } | Should -Throw $errorRecord
            }
        }
    }

    Context 'Invoking with valid interface alias and one NetworkCategory' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name = 'TestAdapter'
                }
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testNetworkCategoryMatches = @{
                    InterfaceAlias  = 'TestAdapter'
                    NetworkCategory = 'Public'
                }

                { Assert-ResourceProperty @testNetworkCategoryMatches } | Should -Not -Throw
            }
        }
    }

    Context 'Invoking with valid interface alias and one IPv4Connectivity' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name = 'TestAdapter'
                }
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv4ConnectivityMatches = @{
                    InterfaceAlias   = 'TestAdapter'
                    IPv4Connectivity = 'Internet'
                }

                { Assert-ResourceProperty @testIPv4ConnectivityMatches } | Should -Not -Throw
            }
        }
    }

    Context 'Invoking with valid interface alias and one IPv6Connectivity' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name = 'TestAdapter'
                }
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv6ConnectivityMatches = @{
                    InterfaceAlias   = 'TestAdapter'
                    IPv6Connectivity = 'Internet'
                }

                { Assert-ResourceProperty @testIPv6ConnectivityMatches } | Should -Not -Throw
            }
        }
    }
}
