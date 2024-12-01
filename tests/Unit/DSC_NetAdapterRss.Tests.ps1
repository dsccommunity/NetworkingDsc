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
    $script:dscResourceName = 'DSC_NetAdapterRss'

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

Describe 'DSC_NetAdapterRss\Get-TargetResource' -Tag 'Get' {
    Context 'Adapter exist and RSS is enabled' {
        BeforeAll {
            Mock Get-NetAdapterRss -Verbose -MockWith {
                @{ Enabled = $true }
            }
        }

        It 'Should return the RSS Enabled' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestRssEnabled = @{
                    Name    = 'Ethernet'
                    Enabled = $true
                }

                $result = Get-TargetResource @TestRssEnabled

                $result.Enabled | Should -Be $TestRSSEnabled.Enabled
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRSS -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter exist and RSS is disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRSS -MockWith {
                @{ Enabled = $false }
            }
        }

        It 'Should return the RSS Enabled' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestRssDisabled = @{
                    Name    = 'Ethernet'
                    Enabled = $false
                }

                $result = Get-TargetResource @TestRSSDisabled

                $result.Enabled | Should -Be $TestRSSDisabled.Enabled
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRSS -Exactly -Time 1 -Scope Context
        }
    }
    Context 'Adapter does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRss -MockWith { throw 'Network adapter not found' }
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestAdapterNotFound = @{
                    Name    = 'Ethe'
                    Enabled = $true
                }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundMessage)

                { Get-TargetResource @TestAdapterNotFound } | Should -Throw $errorRecord
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRss -Exactly -Time 1 -Scope Context
        }
    }
}

Describe 'DSC_NetAdapterRss\Set-TargetResource' -Tag 'Set' {
    Context 'Adapter exist, RSS is enabled, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRSS -MockWith {
                @{ Enabled = $true }
            }

            Mock -CommandName Set-NetAdapterRSS
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestRssEnabled = @{
                    Name    = 'Ethernet'
                    Enabled = $true
                }

                { Set-TargetResource @TestRSSEnabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRSS -Exactly -Time 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRSS -Exactly -Time 0 -Scope Context
        }
    }

    Context 'Adapter exist, RSS is enabled, should be disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRSS -MockWith {
                @{ Enabled = $true }
            }

            Mock -CommandName Set-NetAdapterRSS
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestRssDisabled = @{
                    Name    = 'Ethernet'
                    Enabled = $false
                }

                { Set-TargetResource @TestRSSDisabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRSS -Exactly -Time 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRSS -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter exist, RSS is disabled, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRSS -MockWith {
                @{ Enabled = $false }
            }

            Mock -CommandName Set-NetAdapterRSS
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestRssDisabled = @{
                    Name    = 'Ethernet'
                    Enabled = $false
                }

                { Set-TargetResource @TestRSSDisabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRSS -Exactly -Time 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRSS -Exactly -Time 0 -Scope Context
        }
    }

    Context 'Adapter exist, RSS is disabled, should be enabled.' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRSS -MockWith {
                @{ Enabled = $false }
            }

            Mock -CommandName Set-NetAdapterRSS
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestRssEnabled = @{
                    Name    = 'Ethernet'
                    Enabled = $true
                }

                { Set-TargetResource @TestRSSEnabled } | Should -Not -Throw
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRSS -Exactly -Time 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRSS -Exactly -Time 1 -Scope Context
        }
    }

    # Adapter
    Context 'Adapter does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRSS -MockWith { throw 'Network adapter not found' }
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestAdapterNotFound = @{
                    Name    = 'Ethe'
                    Enabled = $true
                }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundMessage)

                { Set-TargetResource @TestAdapterNotFound } | Should -Throw $errorRecord
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRSS -Exactly -Time 1 -Scope Context
        }
    }

}

Describe 'DSC_NetAdapterRss\Test-TargetResource' -Tag 'Test' {
    # All
    Context 'Adapter exist, RSS is enabled, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRSS -MockWith {
                @{ Enabled = $true }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestRssEnabled = @{
                    Name    = 'Ethernet'
                    Enabled = $true
                }

                Test-TargetResource @TestRSSEnabled | Should -BeTrue
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRSS -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter exist, RSS is enabled, should be disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRSS -MockWith {
                @{ Enabled = $true }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestRssDisabled = @{
                    Name    = 'Ethernet'
                    Enabled = $false
                }

                Test-TargetResource @TestRSSDisabled | Should -BeFalse
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRSS -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter exist, RSS is disabled, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRSS -MockWith {
                @{ Enabled = $false }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestRssDisabled = @{
                    Name    = 'Ethernet'
                    Enabled = $false
                }

                Test-TargetResource @TestRSSDisabled | Should -BeTrue
            }
        }

        it 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRSS -Exactly -Time 1 -Scope Context
        }
    }

    Context 'Adapter exist, RSS is disabled, should be enabled.' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRSS -MockWith {
                @{ Enabled = $false }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestRssEnabled = @{
                    Name    = 'Ethernet'
                    Enabled = $true
                }

                Test-TargetResource @TestRSSEnabled | Should -BeFalse
            }
        }

        it 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRSS -Exactly -Time 1 -Scope Context
        }
    }

    # Adapter
    Context 'Adapter does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRSS -MockWith { throw 'Network adapter not found' }
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $TestAdapterNotFound = @{
                    Name    = 'Ethe'
                    Enabled = $true
                }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundMessage)

                { Test-TargetResource @TestAdapterNotFound } | Should -Throw $errorRecord
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapterRSS -Exactly -Time 1 -Scope Context
        }
    }
}
