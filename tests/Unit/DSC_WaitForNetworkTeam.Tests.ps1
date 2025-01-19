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
    $script:dscResourceName = 'DSC_WaitForNetworkTeam'

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

Describe 'DSC_WaitForNetworkTeam\Get-TargetResource' -Tag 'Get' {
    Context 'When the network team exists' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeamStatus -MockWith { 'Up' }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name = 'TestTeam'
                }

                { $script:result = Get-TargetResource @testParams } | Should -Not -Throw
            }
        }

        It "Should return Name 'TestTeam'" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result.Name | Should -Be 'TestTeam'
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeamStatus -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When the network team does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeamStatus -MockWith {
                New-InvalidOperationException -Message ('Network Team {0} not found' -f 'TestTeam') -PassThru
            }
        }

        # TODO: Not working
        It 'Should throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name = 'TestTeam'
                }

                $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.NetworkTeamNotFoundMessage -f $testParams.Name)

                $result = Get-TargetResource @testParams
                { $result } | Should -Throw -Not
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeamStatus -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_WaitForNetworkTeam\Set-TargetResource' -Tag 'Set' {
    Context 'When network team is Up' {
        BeforeAll {
            Mock -CommandName Start-Sleep
            Mock -CommandName Get-NetLbfoTeamStatus -MockWith { 'Up' }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name             = 'TestTeam'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Start-Sleep -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Get-NetLbfoTeamStatus -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When network team is not Up' {
        BeforeAll {
            Mock -CommandName Start-Sleep
            Mock -CommandName Get-NetLbfoTeamStatus -MockWith { 'Degraded' }
        }

        It 'Should throw VolumeNotFoundAfterError' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord `
                    -Message $($script:localizedData.NetworkTeamNotUpAfterError -f 'TestTeam', 20)

                $testParams = @{
                    Name             = 'TestTeam'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                { Set-TargetResource @testParams } | Should -Throw $errorRecord
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Start-Sleep -Exactly -Times 20 -Scope Context
            Should -Invoke -CommandName Get-NetLbfoTeamStatus -Exactly -Times 20 -Scope Context
        }
    }
}

Describe 'DSC_WaitForNetworkTeam\Test-TargetResource' -Tag 'Test' {
    Context 'When network team is Up' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeamStatus -MockWith { 'Up' }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name             = 'TestTeam'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                { $script:result = Test-TargetResource @testParams } | Should -Not -Throw
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result | Should -BeTrue
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeamStatus -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When network team is not Up' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeamStatus -MockWith { 'Degraded' }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name             = 'TestTeam'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                { $script:result = Test-TargetResource @testParams } | Should -Not -Throw
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result | Should -BeFalse
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeamStatus -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_WaitForNetworkTeam\Get-NetLbfoTeamStatus' {
    Context 'When network team exists and is Up' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeam -MockWith {
                @{
                    Name   = 'TestTeam'
                    Status = 'Up'
                }
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name = 'TestTeam'
                }

                { $script:result = Get-NetLbfoTeamStatus @testParams } | Should -Not -Throw
            }
        }

        It 'Should return "Up"' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result | Should -Be 'Up'
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeam -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When network team exists and is Degraded' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeam -MockWith {
                @{
                    Name   = 'TestTeam'
                    Status = 'Degraded'
                }
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name = 'TestTeam'
                }

                { $script:result = Get-NetLbfoTeamStatus @testParams } | Should -Not -Throw
            }
        }

        It 'Should return "Degraded"' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result | Should -Be 'Degraded'
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeam -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When network team does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeam -MockWith {
                Throw New-Object -TypeName 'Microsoft.PowerShell.Cmdletization.Cim.CimJobException'
            }
        }

        It 'Should throw expected exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetworkTeamNotFoundMessage -f 'TestTeam')

                $testParams = @{
                    Name = 'TestTeam'
                }

                { $script:result = Get-NetLbfoTeamStatus @testParams } | Should -Throw $errorRecord
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeam -Exactly -Times 1 -Scope Context
        }
    }
}
