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
    $script:dscResourceName = 'DSC_NetAdapterBinding'

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

Describe 'DSC_NetAdapterBinding\Get-TargetResource' -Tag 'Get' {
    Context 'Adapter exists and binding Enabled' {
        BeforeAll {
            Mock -CommandName Get-Binding -MockWith {
                @{
                    InterfaceAlias = 'Ethernet'
                    ComponentId    = 'ms_tcpip63'
                    Enabled        = $true
                }
            }
        }

        It 'Should return existing binding' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testBindingEnabled = @{
                    InterfaceAlias = 'Ethernet'
                    ComponentId    = 'ms_tcpip63'
                    State          = 'Enabled'
                }

                $result = Get-TargetResource @testBindingEnabled

                $result.InterfaceAlias | Should -Be $testBindingEnabled.InterfaceAlias
                $result.ComponentId | Should -Be $testBindingEnabled.ComponentId
                $result.State | Should -Be 'Enabled'
                $result.CurrentState | Should -Be 'Enabled'
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -CommandName Get-Binding -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exists and binding Disabled' {
        BeforeAll {
            Mock -CommandName Get-Binding -MockWith {
                @{
                    InterfaceAlias = 'Ethernet'
                    ComponentId    = 'ms_tcpip63'
                    Enabled        = $False
                }
            }
        }

        It 'Should return existing binding' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testBindingDisabled = @{
                    InterfaceAlias = 'Ethernet'
                    ComponentId    = 'ms_tcpip63'
                    State          = 'Disabled'
                }

                $result = Get-TargetResource @testBindingDisabled

                $result.InterfaceAlias | Should -Be $testBindingDisabled.InterfaceAlias
                $result.ComponentId | Should -Be $testBindingDisabled.ComponentId
                $result.State | Should -Be 'Disabled'
                $result.CurrentState | Should -Be 'Disabled'
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -CommandName Get-Binding -Exactly -Times 1 -Scope Context
        }
    }

    Context 'More than one Adapter exists and binding is Disabled on one and Enabled on another' {
        BeforeAll {
            Mock -CommandName Get-Binding -MockWith {
                @(
                    @{
                        InterfaceAlias = 'Ethernet'
                        ComponentId    = 'ms_tcpip63'
                        Enabled        = $False
                    },
                    @{
                        InterfaceAlias = 'Ethernet2'
                        ComponentId    = 'ms_tcpip63'
                        Enabled        = $true
                    }
                )
            }
        }

        It 'Should return existing binding' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testBindingMixed = @{
                    InterfaceAlias = '*'
                    ComponentId    = 'ms_tcpip63'
                    State          = 'Enabled'
                }

                $result = Get-TargetResource @testBindingMixed

                $result.InterfaceAlias | Should -Be $testBindingMixed.InterfaceAlias
                $result.ComponentId | Should -Be $testBindingMixed.ComponentId
                $result.State | Should -Be 'Enabled'
                $result.CurrentState | Should -Be 'Mixed'
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -CommandName Get-Binding -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_NetAdapterBinding\Set-TargetResource' -Tag 'Set' {
    Context 'Adapter exists and set binding to Enabled' {
        BeforeAll {
            Mock -CommandName Get-Binding -MockWith {
                @{
                    InterfaceAlias = 'Ethernet'
                    ComponentId    = 'ms_tcpip63'
                    Enabled        = $False
                }
            }
            Mock -CommandName Enable-NetAdapterBinding
            Mock -CommandName Disable-NetAdapterBinding
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testBindingEnabled = @{
                    InterfaceAlias = 'Ethernet'
                    ComponentId    = 'ms_tcpip63'
                    State          = 'Enabled'
                }

                { Set-TargetResource @testBindingEnabled } | Should -Not -Throw
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -CommandName Get-Binding -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Enable-NetAdapterBinding -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Disable-NetAdapterBinding -Exactly -Times 0 -Scope Context
        }
    }

    Context 'Adapter exists and set binding to Disabled' {
        BeforeAll {
            Mock -CommandName Get-Binding -MockWith {
                @{
                    InterfaceAlias = 'Ethernet'
                    ComponentId    = 'ms_tcpip63'
                    Enabled        = $true
                }
            }
            Mock -CommandName Enable-NetAdapterBinding
            Mock -CommandName Disable-NetAdapterBinding
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testBindingDisabled = @{
                    InterfaceAlias = 'Ethernet'
                    ComponentId    = 'ms_tcpip63'
                    State          = 'Disabled'
                }

                { Set-TargetResource @testBindingDisabled } | Should -Not -Throw
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -CommandName Get-Binding -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Enable-NetAdapterBinding -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Disable-NetAdapterBinding -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_NetAdapterBinding\Test-TargetResource' -Tag 'Test' {
    Context 'Adapter exists, current binding set to Enabled but want it Disabled' {
        BeforeAll {
            Mock -CommandName Get-Binding -MockWith {
                @{
                    InterfaceAlias = 'Ethernet'
                    ComponentId    = 'ms_tcpip63'
                    Enabled        = $true
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testBindingDisabled = @{
                    InterfaceAlias = 'Ethernet'
                    ComponentId    = 'ms_tcpip63'
                    State          = 'Disabled'
                }

                Test-TargetResource @testBindingDisabled | Should -BeFalse
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -CommandName Get-Binding -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exists, current binding set to Disabled but want it Enabled' {
        BeforeAll {
            Mock -CommandName Get-Binding -MockWith {
                @{
                    InterfaceAlias = 'Ethernet'
                    ComponentId    = 'ms_tcpip63'
                    Enabled        = $False
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testBindingEnabled = @{
                    InterfaceAlias = 'Ethernet'
                    ComponentId    = 'ms_tcpip63'
                    State          = 'Enabled'
                }

                Test-TargetResource @testBindingEnabled | Should -BeFalse
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -CommandName Get-Binding -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exists, current binding set to Enabled and want it Enabled' {
        BeforeAll {
            Mock -CommandName Get-Binding -MockWith {
                @{
                    InterfaceAlias = 'Ethernet'
                    ComponentId    = 'ms_tcpip63'
                    Enabled        = $true
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testBindingEnabled = @{
                    InterfaceAlias = 'Ethernet'
                    ComponentId    = 'ms_tcpip63'
                    State          = 'Enabled'
                }

                Test-TargetResource @testBindingEnabled | Should -BeTrue
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -CommandName Get-Binding -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exists, current binding set to Disabled and want it Disabled' {
        BeforeAll {
            Mock -CommandName Get-Binding -MockWith {
                @{
                    InterfaceAlias = 'Ethernet'
                    ComponentId    = 'ms_tcpip63'
                    Enabled        = $False
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testBindingDisabled = @{
                    InterfaceAlias = 'Ethernet'
                    ComponentId    = 'ms_tcpip63'
                    State          = 'Disabled'
                }

                Test-TargetResource @testBindingDisabled | Should -BeTrue
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -CommandName Get-Binding -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_NetAdapterBinding\Get-Binding' {
    Context 'Adapter does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter
        }

        It 'Should throw an InterfaceNotAvailable error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testBindingEnabled = @{
                    InterfaceAlias = 'Ethernet'
                    ComponentId    = 'ms_tcpip63'
                    State          = 'Enabled'
                }

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($script:localizedData.InterfaceNotAvailableError -f $testBindingEnabled.InterfaceAlias) `
                    -ArgumentName 'InterfaceAlias'

                { Get-Binding @testBindingEnabled } | Should -Throw $errorRecord
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exists and binding enabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    InterfaceAlias = 'Ethernet'
                }
            }
            Mock -CommandName Get-NetAdapterBinding -MockWith {
                @{
                    InterfaceAlias = 'Ethernet'
                    ComponentId    = 'ms_tcpip63'
                    Enabled        = $true
                }
            }
        }

        It 'Should return the adapter binding' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testBindingEnabled = @{
                    InterfaceAlias = 'Ethernet'
                    ComponentId    = 'ms_tcpip63'
                    State          = 'Enabled'
                }

                $result = Get-Binding @testBindingEnabled

                $result.InterfaceAlias | Should -Be 'Ethernet'
                $result.ComponentId | Should -Be 'ms_tcpip63'
                $result.Enabled | Should -BeTrue
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Get-NetAdapterBinding -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Adapter exists and binding disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    InterfaceAlias = 'Ethernet'
                }
            }
            Mock -CommandName Get-NetAdapterBinding -MockWith {
                @{
                    InterfaceAlias = 'Ethernet'
                    ComponentId    = 'ms_tcpip63'
                    Enabled        = $False
                }
            }
        }

        It 'Should return the adapter binding' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testBindingDisabled = @{
                    InterfaceAlias = 'Ethernet'
                    ComponentId    = 'ms_tcpip63'
                    State          = 'Disabled'
                }

                $result = Get-Binding @testBindingDisabled

                $result.InterfaceAlias | Should -Be 'Ethernet'
                $result.ComponentId | Should -Be 'ms_tcpip63'
                $result.Enabled | Should -BeFalse
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Get-NetAdapterBinding -Exactly -Times 1 -Scope Context
        }
    }
}
