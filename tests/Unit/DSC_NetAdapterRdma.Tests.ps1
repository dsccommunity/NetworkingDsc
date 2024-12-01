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
    $script:dscResourceName = 'DSC_NetAdapterRdma'

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

Describe 'DSC_NetAdapterRdma\Get-TargetResource' -Tag 'Get' {
    Context 'Network adapter does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRdma -MockWith {
                throw 'Network adapter not found'
            }
        }

        It 'Should throw expected exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $targetParameters = @{
                    Name = 'SMB1_1'
                }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundError -f $targetParameters.Name)

                { Get-TargetResource @targetParameters } | Should -Throw $errorRecord
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-NetAdapterRdma -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Network Team exists' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRdma -MockWith {
                @{
                    Name    = 'SMB1_1'
                    Enabled = $true
                }
            }
        }

        It 'Should return network adapter RDMA properties' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $targetParameters = @{
                    Name = 'SMB1_1'
                }

                $Result = Get-TargetResource @targetParameters

                $Result.Name | Should -Be $targetParameters.Name
                $Result.Enabled | Should -BeTrue
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-NetAdapterRdma -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_NetAdapterRdma\Set-TargetResource' -Tag 'Set' {
    Context 'Net Adapter does not exist' {
        BeforeAll {
            Mock -CommandName Set-NetAdapterRdma
            Mock -CommandName Get-NetAdapterRdma -MockWith {
                throw 'Network adapter not found'
            }
        }

        It 'Should throw expected exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $targetParameters = @{
                    Name = 'SMB1_1'
                }

                $targetParameters.Enabled = $true

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundError -f $targetParameters.Name)

                { Set-TargetResource @targetParameters } | Should -Throw $errorRecord
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetAdapterRdma -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRdma -Exactly -Times 0 -Scope Context
        }
    }

    Context 'Net Adapter RDMA is already enabled and no action needed' {
        BeforeAll {
            Mock -CommandName Set-NetAdapterRdma
            Mock -CommandName Get-NetAdapterRdma -MockWith {
                @{
                    Name    = 'SMB1_1'
                    Enabled = $true
                }
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $targetParameters = @{
                    Name = 'SMB1_1'
                }

                $targetParameters.Enabled = $true

                { Set-TargetResource @targetParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetAdapterRdma -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRdma -Exactly -Times 0 -Scope Context
        }
    }

    Context 'Net Adapter RDMA is disabled and should be enabled' {
        BeforeAll {
            Mock -CommandName Set-NetAdapterRdma
            Mock -CommandName Get-NetAdapterRdma -MockWith {
                @{
                    Name    = 'SMB1_1'
                    Enabled = $false
                }
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $targetParameters = @{
                    Name = 'SMB1_1'
                }

                $targetParameters.Enabled = $true

                { Set-TargetResource @targetParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetAdapterRdma -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRdma -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Net Adapter RDMA is enabled and should be disabled' {
        BeforeAll {
            Mock -CommandName Set-NetAdapterRdma
            Mock -CommandName Get-NetAdapterRdma -MockWith {
                @{
                    Name    = 'SMB1_1'
                    Enabled = $true
                }
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $targetParameters = @{
                    Name = 'SMB1_1'
                }

                $targetParameters.Enabled = $false

                { Set-TargetResource @targetParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetAdapterRdma -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRdma -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Net Adapter RDMA is already disabled and no action needed' {
        BeforeAll {
            Mock -CommandName Set-NetAdapterRdma
            Mock -CommandName Get-NetAdapterRdma -MockWith {
                @{
                    Name    = 'SMB1_1'
                    Enabled = $false
                }
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $targetParameters = @{
                    Name = 'SMB1_1'
                }

                $targetParameters.Enabled = $false

                { Set-TargetResource @targetParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetAdapterRdma -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetAdapterRdma -Exactly -Times 0 -Scope Context
        }
    }
}

Describe 'DSC_NetAdapterRdma\Test-TargetResource' -Tag 'Test' {
    Context 'Net Adapter does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRdma -MockWith {
                throw 'Network adapter not found'
            }
        }

        It 'Should throw expected exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $targetParameters = @{
                    Name = 'SMB1_1'
                }

                $targetParameters.Enabled = $true

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundError -f $targetParameters.Name)

                { Test-TargetResource @targetParameters } | Should -Throw $errorRecord
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetAdapterRdma -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Net Adapter RDMA is already enabled and no action needed' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRdma -MockWith {
                @{
                    Name    = 'SMB1_1'
                    Enabled = $true
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $targetParameters = @{
                    Name = 'SMB1_1'
                }

                $targetParameters.Enabled = $true

                Test-TargetResource @targetParameters | Should -BeTrue
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetAdapterRdma -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Net Adapter RDMA is disabled and should be enabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRdma -MockWith {
                @{
                    Name    = 'SMB1_1'
                    Enabled = $false
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $targetParameters = @{
                    Name = 'SMB1_1'
                }

                $targetParameters.Enabled = $true

                Test-TargetResource @targetParameters | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetAdapterRdma -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Net Adapter RDMA is enabled and should be disabled' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRdma -MockWith {
                @{
                    Name    = 'SMB1_1'
                    Enabled = $true
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $targetParameters = @{
                    Name = 'SMB1_1'
                }

                $targetParameters.Enabled = $false

                Test-TargetResource @targetParameters | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetAdapterRdma -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Net Adapter RDMA is already disabled and no action needed' {
        BeforeAll {
            Mock -CommandName Get-NetAdapterRdma -MockWith {
                @{
                    Name    = 'SMB1_1'
                    Enabled = $false
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $targetParameters = @{
                    Name = 'SMB1_1'
                }

                $targetParameters.Enabled = $false

                Test-TargetResource @targetParameters | Should -BeTrue
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetAdapterRdma -Exactly -Times 1 -Scope Context
        }
    }
}
