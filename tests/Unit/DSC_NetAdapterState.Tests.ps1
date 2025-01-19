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
    $script:dscResourceName = 'DSC_NetAdapterState'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    # Import the NetAdapter module to load the required NET_IF_ADMIN_STATUS enums
    Import-Module -Name NetAdapter

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

    # Remove module NetAdapter.
    Get-Module -Name 'NetAdapter' -All | Remove-Module -Force

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force
}

Describe 'DSC_NetAdapterState\Get-TargetResource' -Tag 'Get' {
    Context 'When adapter exists and is enabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name        = 'Ethernet'
                    AdminStatus = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetAdapter.NET_IF_ADMIN_STATUS]::Up
                    State       = 'Enabled'
                }
            }
        }

        It 'Should return the state of the network adapter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetResource = @{
                    Name  = 'Ethernet'
                    State = 'Enabled'
                }

                $result = Get-TargetResource @getTargetResource

                $result.State | Should -Be 'Enabled'
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When adapter exists and is in unsupported state' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name        = 'Ethernet'
                    AdminStatus = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetAdapter.NET_IF_ADMIN_STATUS]::Testing
                }
            }
        }

        It 'Should return the state of the network adapter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetResource = @{
                    Name  = 'Ethernet'
                    State = 'Enabled'
                }

                $result = Get-TargetResource @getTargetResource

                $result.State | Should -Be 'Unsupported'
            }
        }
    }

    Context 'When adapter exists and is disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name        = 'Ethernet'
                    AdminStatus = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetAdapter.NET_IF_ADMIN_STATUS]::Down
                    State       = 'Disabled'
                }
            }
        }

        It 'Should return the state of the network adapter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetResource = @{
                    Name  = 'Ethernet'
                    State = 'Enabled'
                }

                $result = Get-TargetResource @getTargetResource

                $result.State | Should -Be 'Disabled'
            }
        }

        It 'Should call all mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When Get-NetAdapter returns error' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                throw 'Throwing from Get-NetAdapter'
            }
        }

        It 'Should display warning when network adapter cannot be found' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetResource = @{
                    Name  = 'Ethernet'
                    State = 'Enabled'
                }

                $warning = Get-TargetResource @getTargetResource 3>&1

                $warning.Message | Should -Be "Get-TargetResource: Network adapter 'Ethernet' not found."
            }
        }
    }
}

Describe 'DSC_NetAdapterState\Set-TargetResource' -Tag 'Set' {
    Context 'When adapter exists and is enabled, desired state is enabled, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name        = 'Ethernet'
                    AdminStatus = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetAdapter.NET_IF_ADMIN_STATUS]::Up
                    State       = 'Enabled'
                }
            }

            Mock -CommandName Disable-NetAdapter
            Mock -CommandName Enable-NetAdapter
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceEnabled = @{
                    Name  = 'Ethernet'
                    State = 'Enabled'
                }

                { Set-TargetResource @setTargetResourceEnabled } | Should -Not -Throw
            }
        }

        It 'Should not call Disable-NetAdapter' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Disable-NetAdapter -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Enable-NetAdapter -Exactly -Times 0 -Scope Context
        }
    }

    Context 'When adapter exists and is enabled, desired state is disabled, should be disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name        = 'Ethernet'
                    AdminStatus = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetAdapter.NET_IF_ADMIN_STATUS]::Up
                    State       = 'Enabled'
                }
            }

            Mock -CommandName Disable-NetAdapter
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceDisabled = @{
                    Name  = 'Ethernet'
                    State = 'Disabled'
                }

                { Set-TargetResource @setTargetResourceDisabled } | Should -Not -Throw
            }
        }

        It 'Should call Disable-NetAdapter' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Disable-NetAdapter -Exactly -Times 1 -Scope Context -ParameterFilter {
                $Name -eq 'Ethernet'
            }
        }
    }

    Context 'When adapter exists and is disabled, desired state is disabled, no action required' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name        = 'Ethernet'
                    AdminStatus = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetAdapter.NET_IF_ADMIN_STATUS]::Down
                    State       = 'Disabled'
                }
            }

            Mock -CommandName Disable-NetAdapter
            Mock -CommandName Enable-NetAdapter
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceDisabled = @{
                    Name  = 'Ethernet'
                    State = 'Disabled'
                }

                { Set-TargetResource @setTargetResourceDisabled } | Should -Not -Throw
            }
        }

        It 'Should not call Enable-NetAdapter' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Disable-NetAdapter -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Enable-NetAdapter -Exactly -Times 0 -Scope Context
        }
    }

    Context 'When adapter exists and is disabled, desired state is enabled, should be enabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name        = 'Ethernet'
                    AdminStatus = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetAdapter.NET_IF_ADMIN_STATUS]::Down
                    State       = 'Disabled'
                }
            }

            Mock -CommandName Enable-NetAdapter
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceEnabled = @{
                    Name  = 'Ethernet'
                    State = 'Enabled'
                }

                { Set-TargetResource @setTargetResourceEnabled } | Should -Not -Throw
            }
        }

        It 'Should call Enable-NetAdapter' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Enable-NetAdapter -Exactly -Times 1 -Scope Context -ParameterFilter {
                $Name -eq 'Ethernet'
            }
        }
    }

    Context 'When adapter exists and is disabled, desired state is enabled, set failed' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name        = 'Ethernet'
                    AdminStatus = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetAdapter.NET_IF_ADMIN_STATUS]::Down
                    State       = 'Disabled'
                }
            }

            Mock -CommandName Enable-NetAdapter -MockWith {
                throw 'Throwing from Enable-NetAdapter'
            }
        }


        It 'Should raise a non terminating error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceEnabled = @{
                    Name  = 'Ethernet'
                    State = 'Enabled'
                }

                $errorText = "Set-TargetResource: Failed to set network adapter 'Ethernet' to state 'Enabled'. Error: 'Throwing from Enable-NetAdapter'."

                $netAdapterError = Set-TargetResource @setTargetResourceEnabled -ErrorAction Continue 2>&1

                $netAdapterError.Exception.Message | Should -Be $errorText
            }
        }
    }

    Context 'When adapter does not exist and desired state is enabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                throw 'Throwing from Get-NetAdapter'
            }
        }


        It 'Should raise a non terminating error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceEnabled = @{
                    Name  = 'Ethernet'
                    State = 'Enabled'
                }

                $errorText = "Set-TargetResource: Network adapter 'Ethernet' not found."

                $netAdapterError = Set-TargetResource @setTargetResourceEnabled -ErrorAction Continue 2>&1

                $netAdapterError.Exception.Message | Should -Be $errorText
            }
        }
    }
}

Describe 'DSC_NetAdapterState\Test-TargetResource' -Tag 'Test' {
    Context 'When adapter exists and is enabled, desired state is enabled, test true' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name        = 'Ethernet'
                    AdminStatus = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetAdapter.NET_IF_ADMIN_STATUS]::Up
                    State       = 'Enabled'
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceEnabled = @{
                    Name  = 'Ethernet'
                    State = 'Enabled'
                }

                Test-TargetResource @testTargetResourceEnabled | Should -BeTrue
            }
        }
    }

    Context 'When adapter exists and is enabled, desired state is disabled, test false' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name        = 'Ethernet'
                    AdminStatus = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetAdapter.NET_IF_ADMIN_STATUS]::Up
                    State       = 'Enabled'
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceDisabled = @{
                    Name  = 'Ethernet'
                    State = 'Disabled'
                }

                Test-TargetResource @testTargetResourceDisabled | Should -BeFalse
            }
        }
    }

    Context 'When adapter exists and is disabled, desired state is disabled, test true' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name        = 'Ethernet'
                    AdminStatus = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetAdapter.NET_IF_ADMIN_STATUS]::Down
                    State       = 'Disabled'
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceDisabled = @{
                    Name  = 'Ethernet'
                    State = 'Disabled'
                }

                Test-TargetResource @testTargetResourceDisabled | Should -BeTrue
            }
        }
    }

    Context 'When adapter exists and is disabled, desired state is enabled, test false' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name        = 'Ethernet'
                    AdminStatus = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetAdapter.NET_IF_ADMIN_STATUS]::Down
                    State       = 'Disabled'
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceEnabled = @{
                    Name  = 'Ethernet'
                    State = 'Enabled'
                }

                Test-TargetResource @testTargetResourceEnabled | Should -BeFalse
            }
        }
    }

    Context 'When adapter exists and is in Unsupported state, desired state is enabled, test false' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name        = 'Ethernet'
                    AdminStatus = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetAdapter.NET_IF_ADMIN_STATUS]::Testing
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceEnabled = @{
                    Name  = 'Ethernet'
                    State = 'Enabled'
                }

                Test-TargetResource @testTargetResourceEnabled | Should -BeFalse
            }
        }
    }

    Context 'When adapter does not exist, desired state is enabled, test false' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                $null
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceEnabled = @{
                    Name  = 'Ethernet'
                    State = 'Enabled'
                }

                Test-TargetResource @testTargetResourceEnabled | Should -BeFalse
            }
        }
    }
}
