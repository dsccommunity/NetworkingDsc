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
    $script:dscResourceName = 'DSC_NetAdapterRsc'

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

Describe 'DSC_NetAdapterRsc\Get-TargetResource' -Tag 'Get' {
    Context 'Adapter exists and Rsc is enabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{
                    IPv4Enabled = $true
                    IPv6Enabled = $true
                }
            }
        }

        It 'Should return the Rsc state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestAllRscEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'All'
                    State    = $true
                }

                $result = Get-TargetResource @TestAllRscEnabled

                $result.StateIPv4 | Should -Be $TestAllRscEnabled.State
                $result.StateIPv6 | Should -Be $TestAllRscEnabled.State
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter exists and Rsc is disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{
                    IPv4Enabled = $false
                    IPv6Enabled = $false
                }
            }
        }

        It 'Should return the Rsc state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestAllRscDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'All'
                    State    = $false
                }

                $result = Get-TargetResource @TestAllRscDisabled

                $result.StateIPv4 | Should -Be $TestAllRscDisabled.State
                $result.StateIPv6 | Should -Be $TestAllRscDisabled.State
            }

        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }


    Context 'Adapter exists and Rsc for IPv4 is enabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{
                    IPv4Enabled = $true
                }
            }
        }

        It 'Should return the Rsc state of IPv4' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestIPv4RscEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv4'
                    State    = $true
                }

                $result = Get-TargetResource @TestIPv4RscEnabled

                $result.State | Should -Be $TestIPv4RscEnabled.State
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter exists and Rsc for IPv4 is disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{
                    IPv4Enabled = $false
                }
            }
        }

        It 'Should return the Rsc state of IPv4' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestIPv4RscDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv4'
                    State    = $false
                }

                $result = Get-TargetResource @TestIPv4RscDisabled
                $result.State | Should -Be $TestIPv4RscDisabled.State
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter exists and Rsc for IPv6 is enabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{
                    IPv6Enabled = $true
                }
            }
        }

        It 'Should return the Rsc state of IPv6' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestIPv6RscEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv6'
                    State    = $true
                }

                $result = Get-TargetResource @TestIPv6RscEnabled

                $result.State | Should -Be $TestIPv6RscEnabled.State
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter exists and Rsc for IPv6 is disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{
                    IPv6Enabled = $false
                }
            }
        }

        It 'Should return the Rsc state of IPv6' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestIPv6RscDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv6'
                    State    = $false
                }

                $result = Get-TargetResource @TestIPv6RscDisabled

                $result.State | Should -Be $TestIPv6RscDisabled.State
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith { throw 'Network adapter not found' }
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestAdapterNotFound = @{
                    Name     = 'Eth'
                    Protocol = 'IPv4'
                    State    = $true
                }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundMessage)

                { Get-TargetResource @TestAdapterNotFound } | Should -Throw $errorRecord
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }
}

Describe 'DSC_NetAdapterRsc\Set-TargetResource' -Tag 'Set' {
    # All
    Context 'Adapter exists, Rsc is enabled, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{
                    IPv4Enabled = $true
                    IPv6Enabled = $true
                }
            }

            Mock -CommandName Set-NetAdapterRsc
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestAllRscEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'All'
                    State    = $true
                }

                { Set-TargetResource @TestAllRscEnabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRsc -Exactly -Time 0 -Scope Context
        }
    }

    Context 'Adapter exists, Rsc is enabled, should be disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{
                    IPv4Enabled = $true
                    IPv6Enabled = $true
                }
            }

            Mock -CommandName Set-NetAdapterRsc
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestAllRscDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'All'
                    State    = $false
                }

                { Set-TargetResource @TestAllRscDisabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRsc -Exactly -Time 2 -Scope Context
        }
    }

    Context 'Adapter exists, Rsc is disabled, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{
                    IPv4Enabled = $false
                    IPv6Enabled = $false
                }
            }

            Mock -CommandName Set-NetAdapterRsc
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestAllRscDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'All'
                    State    = $false
                }

                { Set-TargetResource @TestAllRscDisabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRsc -Exactly -Time 0 -Scope Context
        }
    }

    Context 'Adapter exists, Rsc is disabled, should be enabled.' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{
                    IPv4Enabled = $false
                    IPv6Enabled = $false
                }
            }

            Mock -CommandName Set-NetAdapterRsc
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestAllRscEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'All'
                    State    = $true
                }

                { Set-TargetResource @TestAllRscEnabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRsc -Exactly -Time 2 -Scope Context
        }
    }

    Context 'Adapter exists, Rsc is disabled for IPv4, should be enabled.' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{
                    IPv4Enabled = $false
                    IPv6Enabled = $true
                }
            }

            Mock -CommandName Set-NetAdapterRsc
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestAllRscEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'All'
                    State    = $true
                }

                { Set-TargetResource @TestAllRscEnabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter exists, Rsc is Enabled for IPv6, should be disabled.' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{
                    IPv4Enabled = $false
                    IPv6Enabled = $true
                }
            }

            Mock -CommandName Set-NetAdapterRsc
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestAllRscDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'All'
                    State    = $false
                }

                { Set-TargetResource @TestAllRscDisabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    # IPv4
    Context 'Adapter exists, Rsc is enabled for IPv4, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{ IPv4Enabled = $true }
            }

            Mock -CommandName Set-NetAdapterRsc
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestIPv4RscEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv4'
                    State    = $true
                }

                { Set-TargetResource @TestIPv4RscEnabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRsc -Exactly -Time 0 -Scope Context
        }
    }

    Context 'Adapter exists, Rsc is enabled for IPv4, should be disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{ IPv4Enabled = $true }
            }

            Mock -CommandName Set-NetAdapterRsc
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestIPv4RscDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv4'
                    State    = $false
                }

                { Set-TargetResource @TestIPv4RscDisabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter exists, Rsc is disabled for IPv4, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{ IPv4Enabled = $false }
            }

            Mock -CommandName Set-NetAdapterRsc
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestIPv4RscDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv4'
                    State    = $false
                }

                { Set-TargetResource @TestIPv4RscDisabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRsc -Exactly -Time 0 -Scope Context
        }
    }

    Context 'Adapter exists, Rsc is disabled for IPv4, should be enabled.' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{ IPv4Enabled = $false }
            }

            Mock -CommandName Set-NetAdapterRsc
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestIPv4RscEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv4'
                    State    = $true
                }

                { Set-TargetResource @TestIPv4RscEnabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    # IPv6
    Context 'Adapter exists, Rsc is enabled for IPv6, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{ IPv6Enabled = $true }
            }

            Mock -CommandName Set-NetAdapterRsc
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestIPv6RscEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv6'
                    State    = $true
                }

                { Set-TargetResource @TestIPv6RscEnabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRsc -Exactly -Time 0 -Scope Context
        }
    }

    Context 'Adapter exists, Rsc is enabled for IPv6, should be disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{ IPv6Enabled = $true }
            }

            Mock -CommandName Set-NetAdapterRsc
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestIPv6RscDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv6'
                    State    = $false
                }

                { Set-TargetResource @TestIPv6RscDisabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter exists, Rsc is disabled for IPv6, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{ IPv6Enabled = $false }
            }

            Mock -CommandName Set-NetAdapterRsc
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestIPv6RscDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv6'
                    State    = $false
                }

                { Set-TargetResource @TestIPv6RscDisabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRsc -Exactly -Time 0 -Scope Context
        }
    }

    Context 'Adapter exists, Rsc is disabled for IPv6, should be enabled.' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{ IPv6Enabled = $false }
            }

            Mock -CommandName Set-NetAdapterRsc
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestIPv6RscEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv6'
                    State    = $true
                }

                { Set-TargetResource @TestIPv6RscEnabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    # Adapter
    Context 'Adapter does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith { throw 'Network adapter not found' }
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestAdapterNotFound = @{
                    Name     = 'Eth'
                    Protocol = 'IPv4'
                    State    = $true
                }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundMessage)

                { Set-TargetResource @TestAdapterNotFound } | Should -Throw $errorRecord
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }
}

Describe 'DSC_NetAdapterRsc\Test-TargetResource' -Tag 'Test' {
    # All
    Context 'Adapter exists, Rsc is enabled, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{
                    IPv4Enabled = $true
                    IPv6Enabled = $true
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestAllRscEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'All'
                    State    = $true
                }

                Test-TargetResource @TestAllRscEnabled | Should -BeTrue
            }
        }

        it 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter exists, Rsc is enabled, should be disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{
                    IPv4Enabled = $true
                    IPv6Enabled = $true
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestAllRscDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'All'
                    State    = $false
                }

                Test-TargetResource @TestAllRscDisabled | Should -BeFalse
            }
        }

        it 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter exists, Rsc is disabled, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{
                    IPv4Enabled = $false
                    IPv6Enabled = $false
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestAllRscDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'All'
                    State    = $false
                }

                Test-TargetResource @TestAllRscDisabled | Should -BeTrue
            }
        }

        it 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter exists, Rsc is disabled, should be enabled.' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{
                    IPv4Enabled = $false
                    IPv6Enabled = $false
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestAllRscEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'All'
                    State    = $true
                }

                Test-TargetResource @TestAllRscEnabled | Should -BeFalse
            }
        }

        it 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    # IPv4
    Context 'Adapter exists, Rsc is enabled for IPv4, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{ IPv4Enabled = $true }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestIPv4RscEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv4'
                    State    = $true
                }

                Test-TargetResource @TestIPv4RscEnabled | Should -BeTrue
            }
        }

        it 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter exists, Rsc is enabled for IPv4, should be disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{ IPv4Enabled = $true }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestIPv4RscDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv4'
                    State    = $false
                }

                Test-TargetResource @TestIPv4RscDisabled | Should -BeFalse
            }
        }

        it 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter exists, Rsc is disabled for IPv4, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{ IPv4Enabled = $false }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestIPv4RscDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv4'
                    State    = $false
                }

                Test-TargetResource @TestIPv4RscDisabled | Should -BeTrue
            }
        }

        it 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter exists, Rsc is disabled for IPv4, should be enabled.' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{ IPv4Enabled = $false }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestIPv4RscEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv4'
                    State    = $true
                }

                Test-TargetResource @TestIPv4RscEnabled | Should -BeFalse
            }
        }

        it 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    # IPv6
    Context 'Adapter exists, Rsc is enabled for IPv6, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{ IPv6Enabled = $true }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestIPv6RscEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv6'
                    State    = $true
                }

                Test-TargetResource @TestIPv6RscEnabled | Should -BeTrue
            }
        }

        it 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter exists, Rsc is enabled for IPv6, should be disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{ IPv6Enabled = $true }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestIPv6RscDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv6'
                    State    = $false
                }

                Test-TargetResource @TestIPv6RscDisabled | Should -BeFalse
            }
        }

        it 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter exists, Rsc is disabled for IPv6, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{ IPv6Enabled = $false }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestIPv6RscDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv6'
                    State    = $false
                }

                Test-TargetResource @TestIPv6RscDisabled | Should -BeTrue
            }
        }

        it 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter exists, Rsc is disabled for IPv6, should be enabled.' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith {
                @{ IPv6Enabled = $false }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestIPv6RscEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv6'
                    State    = $true
                }

                Test-TargetResource @TestIPv6RscEnabled | Should -BeFalse
            }
        }

        it 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }

    # Adapter
    Context 'Adapter does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRsc -MockWith { throw 'Network adapter not found' }
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestAdapterNotFound = @{
                    Name     = 'Eth'
                    Protocol = 'IPv4'
                    State    = $true
                }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundMessage)

                { Test-TargetResource @TestAdapterNotFound } | Should -Throw $errorRecord
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRsc -Exactly -Time 1 -Scope Context
        }
    }
}
