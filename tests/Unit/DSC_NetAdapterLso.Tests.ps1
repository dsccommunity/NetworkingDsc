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
    $script:dscResourceName = 'DSC_NetAdapterLso'

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

Describe 'DSC_NetAdapterLso\Get-TargetResource' -Tag 'Get' {
    Context 'Adapter exist and LSO for V1IPv4 is enabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    V1IPv4Enabled = $true
                }
            }
        }

        It 'Should return the LSO state of V1IPv4' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testV1IPv4LsoEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'V1IPv4'
                    State    = $true
                }

                $result = Get-TargetResource @testV1IPv4LsoEnabled
                $result.State | Should -BeTrue
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exist and LSO for V1IPv4 is disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    V1IPv4Enabled = $false
                }
            }
        }

        It 'Should return the LSO state of V1IPv4' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testV1IPv4LsoDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'V1IPv4'
                    State    = $false
                }

                $result = Get-TargetResource @testV1IPv4LsoDisabled
                $result.State | Should -Be $testV1IPv4LsoDisabled.State
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exist and LSO for IPv4 is enabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    IPv4Enabled = $true
                }
            }
        }

        It 'Should return the LSO state of IPv4' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv4LsoEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv4'
                    State    = $true
                }

                $result = Get-TargetResource @testIPv4LsoEnabled

                $result.State | Should -Be $testIPv4LsoEnabled.State
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exist and LSO for IPv4 is disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    IPv4Enabled = $false
                }
            }
        }

        It 'Should return the LSO state of IPv4' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv4LsoDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv4'
                    State    = $false
                }

                $result = Get-TargetResource @testIPv4LsoDisabled

                $result.State | Should -Be $testIPv4LsoDisabled.State
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exist and LSO for IPv6 is enabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    IPv6Enabled = $true
                }
            }
        }

        It 'Should return the LSO state of IPv6' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv6LsoEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv6'
                    State    = $true
                }

                $result = Get-TargetResource @testIPv6LsoEnabled

                $result.State | Should -Be $testIPv6LsoEnabled.State
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exist and LSO for IPv6 is disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    IPv6Enabled = $false
                }
            }
        }

        It 'Should return the LSO state of IPv6' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv6LsoDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv6'
                    State    = $false
                }

                $result = Get-TargetResource @testIPv6LsoDisabled

                $result.State | Should -Be $testIPv6LsoDisabled.State
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith { throw 'Network adapter not found' }
        }

        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testAdapterNotFound = @{
                    Name     = 'Eth'
                    Protocol = 'IPv4'
                    State    = $true
                }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundMessage)

                { Get-TargetResource @testAdapterNotFound } | Should -Throw $errorRecord
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_NetAdapterLso\Set-TargetResource' -Tag 'Set' {
    # V1IPv4
    Context 'Adapter exist, LSO is enabled for V1IPv4, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{ V1IPv4Enabled = $true }
            }
            Mock -CommandName Set-NetAdapterLso
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testV1IPv4LsoEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'V1IPv4'
                    State    = $true
                }

                { Set-TargetResource @testV1IPv4LsoEnabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterLso -Exactly -Times 0 -Scope Context
        }
    }

    Context 'Adapter exist, LSO is enabled for V1IPv4, should be disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    V1IPv4Enabled = $true
                }
            }

            Mock -CommandName Set-NetAdapterLso
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testV1IPv4LsoDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'V1IPv4'
                    State    = $false
                }

                { Set-TargetResource @testV1IPv4LsoDisabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exist, LSO is disabled for V1IPv4, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    V1IPv4Enabled = $false
                }
            }

            Mock -CommandName Set-NetAdapterLso
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testV1IPv4LsoDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'V1IPv4'
                    State    = $false
                }

                { Set-TargetResource @testV1IPv4LsoDisabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterLso -Exactly -Times 0 -Scope Context
        }
    }

    Context 'Adapter exist, LSO is disabled for V1IPv4, should be enabled.' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    V1IPv4Enabled = $false
                }
            }
            Mock -CommandName Set-NetAdapterLso
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testV1IPv4LsoEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'V1IPv4'
                    State    = $true
                }

                { Set-TargetResource @testV1IPv4LsoEnabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    # IPv4
    Context 'Adapter exist, LSO is enabled for IPv4, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    IPv4Enabled = $true
                }
            }

            Mock -CommandName Set-NetAdapterLso
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv4LsoEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv4'
                    State    = $true
                }

                { Set-TargetResource @testIPv4LsoEnabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterLso -Exactly -Times 0 -Scope Context
        }
    }

    Context 'Adapter exist, LSO is enabled for IPv4, should be disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    IPv4Enabled = $true
                }
            }

            Mock -CommandName Set-NetAdapterLso
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv4LsoDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv4'
                    State    = $false
                }

                { Set-TargetResource @testIPv4LsoDisabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exist, LSO is disabled for IPv4, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    IPv4Enabled = $false
                }
            }

            Mock -CommandName Set-NetAdapterLso
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv4LsoDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv4'
                    State    = $false
                }

                { Set-TargetResource @testIPv4LsoDisabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterLso -Exactly -Times 0 -Scope Context
        }
    }

    Context 'Adapter exist, LSO is disabled for IPv4, should be enabled.' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    IPv4Enabled = $false
                }
            }

            Mock -CommandName Set-NetAdapterLso
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv4LsoEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv4'
                    State    = $true
                }

                { Set-TargetResource @testIPv4LsoEnabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    # IPv6
    Context 'Adapter exist, LSO is enabled for IPv6, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    IPv6Enabled = $true
                }
            }

            Mock -CommandName Set-NetAdapterLso
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv6LsoEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv6'
                    State    = $true
                }

                { Set-TargetResource @testIPv6LsoEnabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterLso -Exactly -Times 0 -Scope Context
        }
    }

    Context 'Adapter exist, LSO is enabled for IPv6, should be disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    IPv6Enabled = $true
                }
            }

            Mock -CommandName Set-NetAdapterLso
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv6LsoDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv6'
                    State    = $false
                }

                { Set-TargetResource @testIPv6LsoDisabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exist, LSO is disabled for IPv6, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    IPv6Enabled = $false
                }
            }

            Mock -CommandName Set-NetAdapterLso
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv6LsoDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv6'
                    State    = $false
                }

                { Set-TargetResource @testIPv6LsoDisabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterLso -Exactly -Times 0 -Scope Context
        }
    }

    Context 'Adapter exist, LSO is disabled for IPv6, should be enabled.' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    IPv6Enabled = $false
                }
            }

            Mock -CommandName Set-NetAdapterLso
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv6LsoEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv6'
                    State    = $true
                }

                { Set-TargetResource @testIPv6LsoEnabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    # Adapter
    Context 'Adapter does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith { throw 'Network adapter not found' }
        }

        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testAdapterNotFound = @{
                    Name     = 'Eth'
                    Protocol = 'IPv4'
                    State    = $true
                }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundMessage)

                { Set-TargetResource @testAdapterNotFound } | Should -Throw $errorRecord
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

}

Describe 'DSC_NetAdapterLso\Test-TargetResource' -Tag 'Test' {
    # V1IPv4
    Context 'Adapter exist, LSO is enabled for V1IPv4, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    V1IPv4Enabled = $true
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testV1IPv4LsoEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'V1IPv4'
                    State    = $true
                }

                Test-TargetResource @testV1IPv4LsoEnabled | Should -BeTrue
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exist, LSO is enabled for V1IPv4, should be disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    V1IPv4Enabled = $true
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testV1IPv4LsoDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'V1IPv4'
                    State    = $false
                }

                Test-TargetResource @testV1IPv4LsoDisabled | Should -BeFalse
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exist, LSO is disabled for V1IPv4, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    V1IPv4Enabled = $false
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testV1IPv4LsoDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'V1IPv4'
                    State    = $false
                }

                Test-TargetResource @testV1IPv4LsoDisabled | Should -BeTrue
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exist, LSO is disabled for V1IPv4, should be enabled.' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    V1IPv4Enabled = $false
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testV1IPv4LsoEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'V1IPv4'
                    State    = $true
                }

                Test-TargetResource @testV1IPv4LsoEnabled | Should -BeFalse
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    # IPv4
    Context 'Adapter exist, LSO is enabled for IPv4, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    IPv4Enabled = $true
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv4LsoEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv4'
                    State    = $true
                }

                Test-TargetResource @testIPv4LsoEnabled | Should -BeTrue
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exist, LSO is enabled for IPv4, should be disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    IPv4Enabled = $true
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv4LsoDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv4'
                    State    = $false
                }

                Test-TargetResource @testIPv4LsoDisabled | Should -BeFalse
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exist, LSO is disabled for IPv4, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    IPv4Enabled = $false
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv4LsoDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv4'
                    State    = $false
                }

                Test-TargetResource @testIPv4LsoDisabled | Should -BeTrue
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exist, LSO is disabled for IPv4, should be enabled.' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    IPv4Enabled = $false
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv4LsoEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv4'
                    State    = $true
                }

                Test-TargetResource @testIPv4LsoEnabled | Should -BeFalse
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    # IPv6
    Context 'Adapter exist, LSO is enabled for IPv6, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    IPv6Enabled = $true
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv6LsoEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv6'
                    State    = $true
                }

                Test-TargetResource @testIPv6LsoEnabled | Should -BeTrue
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exist, LSO is enabled for IPv6, should be disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    IPv6Enabled = $true
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv6LsoDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv6'
                    State    = $false
                }

                Test-TargetResource @testIPv6LsoDisabled | Should -BeFalse
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exist, LSO is disabled for IPv6, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    IPv6Enabled = $false
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv6LsoDisabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv6'
                    State    = $false
                }

                Test-TargetResource @testIPv6LsoDisabled | Should -BeTrue
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exist, LSO is disabled for IPv6, should be enabled.' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith {
                @{
                    IPv6Enabled = $false
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testIPv6LsoEnabled = @{
                    Name     = 'Ethernet'
                    Protocol = 'IPv6'
                    State    = $true
                }

                Test-TargetResource @testIPv6LsoEnabled | Should -BeFalse
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }

    # Adapter
    Context 'Adapter does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterLso -MockWith { throw 'Network adapter not found' }
        }

        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testAdapterNotFound = @{
                    Name     = 'Eth'
                    Protocol = 'IPv4'
                    State    = $true
                }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundMessage)

                { Test-TargetResource @testAdapterNotFound } | Should -Throw $errorRecord
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterLso -Exactly -Times 1 -Scope Context
        }
    }
}
