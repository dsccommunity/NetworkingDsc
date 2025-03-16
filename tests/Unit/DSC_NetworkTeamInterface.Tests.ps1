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
    $script:dscResourceName = 'DSC_NetworkTeamInterface'

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

Describe 'DSC_NetworkTeamInterface\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        $mockTeamNic = {
            @{
                Name   = 'HostTeamNic'
                Team   = 'HostTeam'
                VlanId = 100
            }
        }

        $getNetLbfoTeamNic_ParameterFilter = {
            $Name -eq 'HostTeamNic' `
                -and $Team -eq 'HostTeam'
        }
    }

    Context 'When team Interface does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTeamNic = @{
                    Name     = 'HostTeamNic'
                    TeamName = 'HostTeam'
                }

                $script:result = Get-TargetResource @testTeamNic
            }
        }

        It 'Should return ensure as absent' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result.Ensure | Should -Be 'Absent'
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Network Team Interface exists' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeamNic -MockWith $mockTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:testTeamNic = @{
                    Name     = 'HostTeamNic'
                    TeamName = 'HostTeam'
                }

                $script:result = Get-TargetResource @testTeamNic
            }
        }

        It 'Should return team properties' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result.Ensure | Should -Be 'Present'
                $script:result.Name | Should -Be $testTeamNic.Name
                $script:result.TeamName | Should -Be $testTeamNic.TeamName
                $script:result.VlanId | Should -Be 100
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_NetworkTeamInterface\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        $mockTeamNic = {
            @{
                Name   = 'HostTeamNic'
                Team   = 'HostTeam'
                VlanId = 100
            }
        }

        $getNetLbfoTeamNic_ParameterFilter = {
            $Name -eq 'HostTeamNic' `
                -and $Team -eq 'HostTeam'
        }

        $addNetLbfoTeamNic_ParameterFilter = {
            $Name -eq 'HostTeamNic' `
                -and $Team -eq 'HostTeam' `
                -and $VlanId -eq 100
        }

        $setNetLbfoTeamNic_ParameterFilter = {
            $Name -eq 'HostTeamNic' `
                -and $Team -eq 'HostTeam' `
                -and $VlanId -eq 105
        }

        $removeNetLbfoTeamNic_ParameterFilter = {
            $Team -eq 'HostTeam' `
                -and $VlanId -eq 100
        }
    }

    Context 'When team Interface does not exist but invalid VlanId (0) is passed' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter
            Mock -CommandName Add-NetLbfoTeamNic
            Mock -CommandName Set-NetLbfoTeamNic
        }


        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.FailedToCreateTeamNic)

                $newTeamNic = @{
                    Name     = 'HostTeamNic'
                    TeamName = 'HostTeam'
                    VlanId   = 100
                }

                $errorTeamNic = $newTeamNic.Clone()
                $errorTeamNic.VlanId = 0

                { Set-TargetResource @errorTeamNic } | Should -Throw $errorRecord
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Add-NetLbfoTeamNic -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Set-NetLbfoTeamNic -Exactly -Times 0 -Scope Context
        }
    }

    Context 'When team Interface does not exist but should' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter
            Mock -CommandName Add-NetLbfoTeamNic -ParameterFilter $addNetLbfoTeamNic_ParameterFilter
            Mock -CommandName Set-NetLbfoTeamNic
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeamNic = @{
                    Name     = 'HostTeamNic'
                    TeamName = 'HostTeam'
                    VlanId   = 100
                }

                { Set-TargetResource @newTeamNic } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Add-NetLbfoTeamNic -ParameterFilter $addNetLbfoTeamNic_ParameterFilter -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetLbfoTeamNic -Exactly -Times 0 -Scope Context
        }
    }

    Context 'When team Interface exists but needs a different VlanId' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter -MockWith $mockTeamNic
            Mock -CommandName Add-NetLbfoTeamNic
            Mock -CommandName Set-NetLbfoTeamNic  -ParameterFilter $setNetLbfoTeamNic_ParameterFilter
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeamNic = @{
                    Name     = 'HostTeamNic'
                    TeamName = 'HostTeam'
                    VlanId   = 100
                }

                $updateTeamNic = $newTeamNic.Clone()
                $updateTeamNic.VlanId = 105

                { Set-TargetResource @updateTeamNic } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Add-NetLbfoTeamNic -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Set-NetLbfoTeamNic -ParameterFilter $setNetLbfoTeamNic_ParameterFilter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When team Interface exists but should not exist' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter -MockWith $mockTeamNic
            Mock -CommandName Add-NetLbfoTeamNic
            Mock -CommandName Set-NetLbfoTeamNic
            Mock -CommandName Remove-NetLbfoTeamNic -ParameterFilter $removeNetLbfoTeamNic_ParameterFilter
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeamNic = @{
                    Name     = 'HostTeamNic'
                    TeamName = 'HostTeam'
                    VlanId   = 100
                }

                $updateTeamNic = $newTeamNic.Clone()
                $updateTeamNic.Ensure = 'Absent'

                { Set-TargetResource @updateTeamNic } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Add-NetLbfoTeamNic -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Set-NetLbfoTeamNic -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Remove-NetLbfoTeamNic  -ParameterFilter $removeNetLbfoTeamNic_ParameterFilter -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_NetworkTeamInterface\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        $mockTeamNic = {
            @{
                Name   = 'HostTeamNic'
                Team   = 'HostTeam'
                VlanId = 100
            }
        }

        $mockTeamNicDefaultVLAN = {
            @{
                Name   = 'HostTeamNic'
                Team   = 'HostTeam'
                VlanId = $null
            }
        }

        $getNetLbfoTeamNic_ParameterFilter = {
            $Name -eq 'HostTeamNic' `
                -and $Team -eq 'HostTeam'
        }
    }

    Context 'When team Interface does not exist but should' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeamNic = @{
                    Name     = 'HostTeamNic'
                    TeamName = 'HostTeam'
                    VlanId   = 100
                }

                { $script:result = Test-TargetResource @newTeamNic } | Should -Not -Throw
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When team Interface exists but needs a different VlanId' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter -MockWith $mockTeamNic
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeamNic = @{
                    Name     = 'HostTeamNic'
                    TeamName = 'HostTeam'
                    VlanId   = 100
                }

                $updateTeamNic = $newTeamNic.Clone()
                $updateTeamNic.VlanId = 105

                $script:result = Test-TargetResource @updateTeamNic
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When team Interface exists but should not exist' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter -MockWith $mockTeamNic
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeamNic = @{
                    Name     = 'HostTeamNic'
                    TeamName = 'HostTeam'
                    VlanId   = 100
                }

                $updateTeamNic = $newTeamNic.Clone()
                $updateTeamNic.Ensure = 'Absent'

                $script:result = Test-TargetResource @updateTeamNic
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When team Interface exists and no action needed' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter -MockWith $mockTeamNic
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeamNic = @{
                    Name     = 'HostTeamNic'
                    TeamName = 'HostTeam'
                    VlanId   = 100
                }

                $updateTeamNic = $newTeamNic.Clone()

                $script:result = Test-TargetResource @updateTeamNic
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result | Should -BeTrue
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When team Interface does not exist and no action needed' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeamNic = @{
                    Name     = 'HostTeamNic'
                    TeamName = 'HostTeam'
                    VlanId   = 100
                }

                $updateTeamNic = $newTeamNic.Clone()
                $updateTeamNic.Ensure = 'Absent'

                $script:result = Test-TargetResource @updateTeamNic
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result | Should -BeTrue
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When team Interface exists on the default 0 VLAN' {
        BeforeAll {
            Mock -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter -MockWith $mockTeamNicDefaultVLAN
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $newTeamNic = @{
                    Name     = 'HostTeamNic'
                    TeamName = 'HostTeam'
                    VlanId   = 100
                }

                $TeamNicOnDefaultVLAN = $newTeamNic.Clone()
                $TeamNicOnDefaultVLAN.VlanId = 0

                $script:result = Test-TargetResource @TeamNicOnDefaultVLAN
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result | Should -BeTrue
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetLbfoTeamNic -ParameterFilter $getNetLbfoTeamNic_ParameterFilter -Exactly -Times 1 -Scope Context
        }
    }
}
