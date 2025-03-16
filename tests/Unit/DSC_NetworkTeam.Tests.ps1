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
    $script:dscResourceName = 'DSC_NetworkTeam'

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

Describe 'DSC_NetworkTeam\Get-TargetResource' -Tag 'Get' {
    Context 'When network team does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeam
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTeam = @{
                    Name        = 'HostTeam'
                    TeamMembers = @('NIC1', 'NIC2')
                }

                $script:result = Get-TargetResource @testTeam
            }
        }

        It 'Should return ensure as absent' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result.Ensure | Should -Be 'Absent'
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeam -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When network team exists with matching members' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeam -MockWith {
                @{
                    Name                   = 'HostTeam'
                    Members                = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:testTeam = @{
                    Name        = 'HostTeam'
                    TeamMembers = @('NIC1', 'NIC2')
                }

                $script:result = Get-TargetResource @testTeam
            }
        }

        It 'Should return team properties' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result.Ensure | Should -Be 'Present'
                $script:result.Name | Should -Be $script:testTeam.Name
                $script:result.TeamMembers | Should -Be $script:testTeam.TeamMembers
                $script:result.LoadBalancingAlgorithm | Should -Be 'Dynamic'
                $script:result.TeamingMode | Should -Be 'SwitchIndependent'
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeam -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When network team exists and different members' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeam -MockWith {
                @{
                    Name                   = 'HostTeam'
                    Members                = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:testTeam = @{
                    Name        = 'HostTeam'
                    TeamMembers = @('NIC1', 'NIC2')
                }

                $script:testTeam.TeamMembers = @('NIC1', 'NIC3')

                $script:result = Get-TargetResource @script:testTeam
            }
        }

        It 'Should return team properties' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result.Ensure | Should -Be 'Present'
                $script:result.Name | Should -Be $script:testTeam.Name
                $script:result.TeamMembers | Should -Be @('NIC1', 'NIC2')
                $script:result.LoadBalancingAlgorithm | Should -Be 'Dynamic'
                $script:result.TeamingMode | Should -Be 'SwitchIndependent'
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeam -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_NetworkTeam\Set-TargetResource' -Tag 'Set' {
    Context 'When team does not exist but should' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeam
            Mock -CommandName New-NetLbfoTeam
            Mock -CommandName Set-NetLbfoTeam
            Mock -CommandName Remove-NetLbfoTeamMember
            Mock -CommandName Add-NetLbfoTeamMember
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeam = @{
                    Name                   = 'HostTeam'
                    TeamMembers            = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }

                { Set-TargetResource @newTeam } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeam -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName New-NetLbfoTeam -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetLbfoTeam -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Remove-NetLbfoTeamMember -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Add-NetLbfoTeamMember -Exactly -Times 0 -Scope Context
        }
    }

    Context 'When team exists but needs a different teaming mode' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeam -MockWith {
                @{
                    Name                   = 'HostTeam'
                    Members                = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }
            }

            Mock -CommandName New-NetLbfoTeam
            Mock -CommandName Set-NetLbfoTeam
            Mock -CommandName Remove-NetLbfoTeam
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeam = @{
                    Name                   = 'HostTeam'
                    TeamMembers            = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }

                $newTeam.TeamingMode = 'LACP'

                { Set-TargetResource @newTeam } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeam -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName New-NetLbfoTeam -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Set-NetLbfoTeam -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Remove-NetLbfoTeam -Exactly -Times 0 -Scope Context
        }
    }

    Context 'When team exists but needs a different load balacing algorithm' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeam -MockWith {
                @{
                    Name                   = 'HostTeam'
                    Members                = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }
            }

            Mock -CommandName New-NetLbfoTeam
            Mock -CommandName Set-NetLbfoTeam
            Mock -CommandName Remove-NetLbfoTeam
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeam = @{
                    Name                   = 'HostTeam'
                    TeamMembers            = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }

                $newTeam.LoadBalancingAlgorithm = 'HyperVPort'

                { Set-TargetResource @newTeam } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeam -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName New-NetLbfoTeam -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Set-NetLbfoTeam -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Remove-NetLbfoTeam -Exactly -Times 0 -Scope Context
        }
    }

    Context 'When team exists but has to remove a member adapter' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeam -MockWith {
                @{
                    Name                   = 'HostTeam'
                    Members                = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }
            }

            Mock -CommandName New-NetLbfoTeam
            Mock -CommandName Set-NetLbfoTeam
            Mock -CommandName Remove-NetLbfoTeam
            Mock -CommandName Remove-NetLbfoTeamMember
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeam = @{
                    Name                   = 'HostTeam'
                    TeamMembers            = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }

                $newTeam.TeamMembers = $newTeam.TeamMembers[0]

                { Set-TargetResource @newTeam } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeam -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName New-NetLbfoTeam -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Set-NetLbfoTeam -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Remove-NetLbfoTeam -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Remove-NetLbfoTeamMember -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When team exists but has to add a member adapter' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeam -MockWith {
                @{
                    Name                   = 'HostTeam'
                    Members                = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }
            }

            Mock -CommandName New-NetLbfoTeam
            Mock -CommandName Set-NetLbfoTeam
            Mock -CommandName Remove-NetLbfoTeam
            Mock -CommandName Remove-NetLbfoTeamMember
            Mock -CommandName Add-NetLbfoTeamMember
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeam = @{
                    Name                   = 'HostTeam'
                    TeamMembers            = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }

                $newTeam.TeamMembers += 'NIC3'

                { Set-TargetResource @newTeam } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeam -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName New-NetLbfoTeam -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Set-NetLbfoTeam -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Remove-NetLbfoTeam -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Remove-NetLbfoTeamMember -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Add-NetLbfoTeamMember -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When team exists but should not exist' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeam -MockWith {
                @{
                    Name                   = 'HostTeam'
                    Members                = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }
            }

            Mock -CommandName New-NetLbfoTeam
            Mock -CommandName Set-NetLbfoTeam
            Mock -CommandName Remove-NetLbfoTeam
            Mock -CommandName Remove-NetLbfoTeamMember
            Mock -CommandName Add-NetLbfoTeamMember
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeam = @{
                    Name                   = 'HostTeam'
                    TeamMembers            = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }

                $newTeam.Ensure = 'Absent'

                { Set-TargetResource @newTeam } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeam -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName New-NetLbfoTeam -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Set-NetLbfoTeam -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Remove-NetLbfoTeam -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Remove-NetLbfoTeamMember -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Add-NetLbfoTeamMember -Exactly -Times 0 -Scope Context
        }
    }
}

Describe 'DSC_NetworkTeam\Test-TargetResource' -Tag 'Test' {
    Context 'When team does not exist but should' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeam
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeam = @{
                    Name                   = 'HostTeam'
                    TeamMembers            = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }

                { $script:Result = Test-TargetResource @newTeam } | Should -Not -Throw
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:Result | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeam -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When team exists but needs a different teaming mode' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeam -MockWith {
                @{
                    Name                   = 'HostTeam'
                    Members                = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }
            }
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeam = @{
                    Name                   = 'HostTeam'
                    TeamMembers            = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }

                $newTeam.TeamingMode = 'LACP'

                { $script:Result = Test-TargetResource @newTeam } | Should -Not -Throw
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:Result | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeam -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When team exists but needs a different load balacing algorithm' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeam -MockWith {
                @{
                    Name                   = 'HostTeam'
                    Members                = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }
            }
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeam = @{
                    Name                   = 'HostTeam'
                    TeamMembers            = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }

                $newTeam.LoadBalancingAlgorithm = 'HyperVPort'

                { $script:Result = Test-TargetResource @newTeam } | Should -Not -Throw
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:Result | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeam -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When team exists but has to remove a member adapter' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeam -MockWith {
                @{
                    Name                   = 'HostTeam'
                    Members                = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }
            }
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeam = @{
                    Name                   = 'HostTeam'
                    TeamMembers            = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }

                $newTeam.TeamMembers = $newTeam.TeamMembers[0]

                { $script:Result = Test-TargetResource @newTeam } | Should -Not -Throw
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:Result | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeam -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When team exists but has to add a member adapter' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeam -MockWith {
                @{
                    Name                   = 'HostTeam'
                    Members                = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }
            }
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeam = @{
                    Name                   = 'HostTeam'
                    TeamMembers            = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }

                $newTeam.TeamMembers += 'NIC3'

                { $script:Result = Test-TargetResource @newTeam } | Should -Not -Throw
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:Result | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeam -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When team exists but should not exist' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeam -MockWith {
                @{
                    Name                   = 'HostTeam'
                    Members                = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }
            }
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeam = @{
                    Name                   = 'HostTeam'
                    TeamMembers            = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }

                $newTeam.Ensure = 'Absent'

                { $script:Result = Test-TargetResource @newTeam } | Should -Not -Throw
            }
        }

        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:Result | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeam -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When team exists and no action needed' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeam -MockWith {
                @{
                    Name                   = 'HostTeam'
                    Members                = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }
            }
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeam = @{
                    Name                   = 'HostTeam'
                    TeamMembers            = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }

                { $script:Result = Test-TargetResource @newTeam } | Should -Not -Throw
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:Result | Should -BeTrue
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeam -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When team does not and no action needed' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeam
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeam = @{
                    Name                   = 'HostTeam'
                    TeamMembers            = @('NIC1', 'NIC2')
                    LoadBalancingAlgorithm = 'Dynamic'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }

                $newTeam.Ensure = 'Absent'

                { $script:Result = Test-TargetResource @newTeam } | Should -Not -Throw
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:Result | Should -BeTrue
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeam -Exactly -Times 1 -Scope Context
        }
    }
}
