
$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_NetworkTeam'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        # Create the Mock -CommandName Objects that will be used for running tests
        $mockNetTeam = [PSCustomObject] @{
            Name    = 'HostTeam'
            Members = @('NIC1', 'NIC2')
        }

        $testTeam = [PSObject] @{
            Name        = $mockNetTeam.Name
            TeamMembers = $mockNetTeam.Members
            Verbose     = $true
        }

        $newTeam = [PSObject] @{
            Name                   = $testTeam.Name
            TeamMembers            = $testTeam.TeamMembers
            LoadBalancingAlgorithm = 'Dynamic'
            TeamingMode            = 'SwitchIndependent'
            Ensure                 = 'Present'
            Verbose                = $true
        }

        $mockTeam = {
            [PSObject] @{
                Name                   = $testTeam.Name
                Members                = $testTeam.TeamMembers
                LoadBalancingAlgorithm = 'Dynamic'
                TeamingMode            = 'SwitchIndependent'
                Ensure                 = 'Present'
            }
        }

        Describe 'DSC_NetworkTeam\Get-TargetResource' -Tag 'Get' {
            Context 'When network team does not exist' {
                Mock -CommandName Get-NetLbfoTeam

                It 'Should not throw exception' {
                    $script:result = Get-TargetResource @testTeam
                }

                It 'Should return ensure as absent' {
                    $script:result.Ensure | Should -Be 'Absent'
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }

            Context 'When network team exists with matching members' {
                Mock -CommandName Get-NetLbfoTeam -MockWith $mockTeam

                It 'Should not throw exception' {
                    $script:result = Get-TargetResource @testTeam
                }

                It 'Should return team properties' {
                    $script:result.Ensure | Should -Be 'Present'
                    $script:result.Name | Should -Be $testTeam.Name
                    $script:result.TeamMembers | Should -Be $testTeam.TeamMembers
                    $script:result.LoadBalancingAlgorithm | Should -Be 'Dynamic'
                    $script:result.TeamingMode | Should -Be 'SwitchIndependent'
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }

            Context 'When network team exists and different members' {
                Mock -CommandName Get-NetLbfoTeam -MockWith $mockTeam

                It 'Should not throw exception' {
                    $getTestTeam = $testTeam.Clone()
                    $getTestTeam.TeamMembers = @('NIC1', 'NIC3')
                    $script:result = Get-TargetResource @getTestTeam
                }

                It 'Should return team properties' {
                    $result.Ensure | Should -Be 'Present'
                    $result.Name | Should -Be $testTeam.Name
                    $result.TeamMembers | Should -Be @('NIC1', 'NIC2')
                    $result.LoadBalancingAlgorithm | Should -Be 'Dynamic'
                    $result.TeamingMode | Should -Be 'SwitchIndependent'
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }
        }

        Describe 'DSC_NetworkTeam\Set-TargetResource' -Tag 'Set' {
            Context 'When team does not exist but should' {
                Mock -CommandName Get-NetLbfoTeam
                Mock -CommandName New-NetLbfoTeam
                Mock -CommandName Set-NetLbfoTeam
                Mock -CommandName Remove-NetLbfoTeamMember
                Mock -CommandName Add-NetLbfoTeamMember

                It 'Should not throw error' {
                    {
                        Set-TargetResource @newTeam
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                    Assert-MockCalled -CommandName New-NetLbfoTeam -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetLbfoTeam -Exactly -Times 0
                    Assert-MockCalled -CommandName Remove-NetLbfoTeamMember -Exactly -Times 0
                    Assert-MockCalled -CommandName Add-NetLbfoTeamMember -Exactly -Times 0
                }
            }

            Context 'When team exists but needs a different teaming mode' {
                Mock -CommandName Get-NetLbfoTeam -MockWith $mockTeam
                Mock -CommandName New-NetLbfoTeam
                Mock -CommandName Set-NetLbfoTeam
                Mock -CommandName Remove-NetLbfoTeam

                It 'Should not throw error' {
                    {
                        $updateTeam = $newTeam.Clone()
                        $updateTeam.TeamingMode = 'LACP'
                        Set-TargetResource @updateTeam
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                    Assert-MockCalled -CommandName New-NetLbfoTeam -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-NetLbfoTeam -Exactly -Times 1
                    Assert-MockCalled -CommandName Remove-NetLbfoTeam -Exactly -Times 0
                }
            }

            Context 'When team exists but needs a different load balacing algorithm' {
                Mock -CommandName Get-NetLbfoTeam -MockWith $mockTeam
                Mock -CommandName New-NetLbfoTeam
                Mock -CommandName Set-NetLbfoTeam
                Mock -CommandName Remove-NetLbfoTeam

                It 'Should not throw error' {
                    {
                        $updateTeam = $newTeam.Clone()
                        $updateTeam.LoadBalancingAlgorithm = 'HyperVPort'
                        Set-TargetResource @updateTeam
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                    Assert-MockCalled -CommandName New-NetLbfoTeam -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-NetLbfoTeam -Exactly -Times 1
                    Assert-MockCalled -CommandName Remove-NetLbfoTeam -Exactly -Times 0
                }
            }

            Context 'When team exists but has to remove a member adapter' {
                Mock -CommandName Get-NetLbfoTeam -MockWith $mockTeam
                Mock -CommandName New-NetLbfoTeam
                Mock -CommandName Set-NetLbfoTeam
                Mock -CommandName Remove-NetLbfoTeam
                Mock -CommandName Remove-NetLbfoTeamMember

                It 'Should not throw error' {
                    {
                        $updateTeam = $newTeam.Clone()
                        $updateTeam.TeamMembers = $newTeam.TeamMembers[0]
                        Set-TargetResource @updateTeam
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                    Assert-MockCalled -CommandName New-NetLbfoTeam -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-NetLbfoTeam -Exactly -Times 0
                    Assert-MockCalled -CommandName Remove-NetLbfoTeam -Exactly -Times 0
                    Assert-MockCalled -CommandName Remove-NetLbfoTeamMember -Exactly -Times 1
                }
            }

            Context 'When team exists but has to add a member adapter' {
                Mock -CommandName Get-NetLbfoTeam -MockWith $mockTeam
                Mock -CommandName New-NetLbfoTeam
                Mock -CommandName Set-NetLbfoTeam
                Mock -CommandName Remove-NetLbfoTeam
                Mock -CommandName Remove-NetLbfoTeamMember
                Mock -CommandName Add-NetLbfoTeamMember

                It 'Should not throw error' {
                    {
                        $updateTeam = $newTeam.Clone()
                        $updateTeam.TeamMembers += 'NIC3'
                        Set-TargetResource @updateTeam
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                    Assert-MockCalled -CommandName New-NetLbfoTeam -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-NetLbfoTeam -Exactly -Times 0
                    Assert-MockCalled -CommandName Remove-NetLbfoTeam -Exactly -Times 0
                    Assert-MockCalled -CommandName Remove-NetLbfoTeamMember -Exactly -Times 0
                    Assert-MockCalled -CommandName Add-NetLbfoTeamMember -Exactly -Times 1
                }
            }

            Context 'When team exists but should not exist' {
                Mock -CommandName Get-NetLbfoTeam -MockWith $mockTeam
                Mock -CommandName New-NetLbfoTeam
                Mock -CommandName Set-NetLbfoTeam
                Mock -CommandName Remove-NetLbfoTeam
                Mock -CommandName Remove-NetLbfoTeamMember
                Mock -CommandName Add-NetLbfoTeamMember

                It 'Should not throw error' {
                    {
                        $updateTeam = $newTeam.Clone()
                        $updateTeam.Ensure = 'Absent'
                        Set-TargetResource @updateTeam
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                    Assert-MockCalled -CommandName New-NetLbfoTeam -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-NetLbfoTeam -Exactly -Times 0
                    Assert-MockCalled -CommandName Remove-NetLbfoTeam -Exactly -Times 1
                    Assert-MockCalled -CommandName Remove-NetLbfoTeamMember -Exactly -Times 0
                    Assert-MockCalled -CommandName Add-NetLbfoTeamMember -Exactly -Times 0
                }
            }
        }

        Describe 'DSC_NetworkTeam\Test-TargetResource' -Tag 'Test' {
            Context 'When team does not exist but should' {
                Mock -CommandName Get-NetLbfoTeam

                It 'Should not throw error' {
                    {
                        $script:Result = Test-TargetResource @newTeam
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:Result | Should -Be $false
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }

            Context 'When team exists but needs a different teaming mode' {
                Mock -CommandName Get-NetLbfoTeam -MockWith $mockTeam

                It 'Should not throw error' {
                    {
                        $updateTeam = $newTeam.Clone()
                        $updateTeam.TeamingMode = 'LACP'
                        $script:Result = Test-TargetResource @updateTeam
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:Result | Should -Be $false
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }

            Context 'When team exists but needs a different load balacing algorithm' {
                Mock -CommandName Get-NetLbfoTeam -MockWith $mockTeam

                It 'Should not throw error' {
                    {
                        $updateTeam = $newTeam.Clone()
                        $updateTeam.LoadBalancingAlgorithm = 'HyperVPort'
                        $script:Result = Test-TargetResource @updateTeam
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:Result | Should -Be $false
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }

            Context 'When team exists but has to remove a member adapter' {
                Mock -CommandName Get-NetLbfoTeam -MockWith $mockTeam

                It 'Should not throw error' {
                    {
                        $updateTeam = $newTeam.Clone()
                        $updateTeam.TeamMembers = $newTeam.TeamMembers[0]
                        $script:Result = Test-TargetResource @updateTeam
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:Result | Should -Be $false
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }

            Context 'When team exists but has to add a member adapter' {
                Mock -CommandName Get-NetLbfoTeam -MockWith $mockTeam

                It 'Should not throw error' {
                    {
                        $updateTeam = $newTeam.Clone()
                        $updateTeam.TeamMembers += 'NIC3'
                        $script:Result = Test-TargetResource @updateTeam
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:Result | Should -Be $false
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }

            Context 'When team exists but should not exist' {
                Mock -CommandName Get-NetLbfoTeam -MockWith $mockTeam

                It 'Should not throw error' {
                    {
                        $updateTeam = $newTeam.Clone()
                        $updateTeam.Ensure = 'Absent'
                        $script:Result = Test-TargetResource @updateTeam
                    } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:Result | Should -Be $false
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }

            Context 'When team exists and no action needed' {
                Mock -CommandName Get-NetLbfoTeam -MockWith $mockTeam

                It 'Should not throw error' {
                    {
                        $updateTeam = $newTeam.Clone()
                        $script:Result = Test-TargetResource @updateTeam
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:Result | Should -Be $true
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }

            Context 'When team does not and no action needed' {
                Mock -CommandName Get-NetLbfoTeam

                It 'Should not throw error' {
                    {
                        $updateTeam = $newTeam.Clone()
                        $updateTeam.Ensure = 'Absent'
                        $script:Result = Test-TargetResource @updateTeam
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:Result | Should -Be $true
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }
        }

    }
}
finally
{
    Invoke-TestCleanup
}
