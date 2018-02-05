$script:DSCModuleName = 'xNetworking'
$script:DSCResourceName = 'MSFT_xNetworkTeam'

#region HEADER
# Unit Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xNetworking'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $script:DSCResourceName {
        # Create the Mock -CommandName Objects that will be used for running tests
        $mockNetTeam = [PSCustomObject] @{
            Name    = 'HostTeam'
            Members = @('NIC1', 'NIC2')
        }

        $testTeam = [PSObject] @{
            Name        = $mockNetTeam.Name
            TeamMembers = $mockNetTeam.Members
        }

        $mockTeam = [PSObject] @{
            Name                   = $testTeam.Name
            Members                = $testTeam.TeamMembers
            LoadBalancingAlgorithm = 'Dynamic'
            TeamingMode            = 'SwitchIndependent'
            Ensure                 = 'Present'
        }

        Describe 'MSFT_xNetworkTeam\Get-TargetResource' {
            Context 'Team does not exist' {
                Mock -CommandName Get-NetLbfoTeam

                It 'Should return ensure as absent' {
                    $Result = Get-TargetResource `
                        @testTeam
                    $Result.Ensure | Should -Be 'Absent'
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }

            Context 'Network Team exists' {
                Mock -CommandName Get-NetLbfoTeam -MockWith { $mockTeam }

                It 'Should return team properties' {
                    $Result = Get-TargetResource @testTeam
                    $Result.Ensure                 | Should -Be 'Present'
                    $Result.Name                   | Should -Be $testTeam.Name
                    $Result.TeamMembers            | Should -Be $testTeam.TeamMembers
                    $Result.LoadBalancingAlgorithm | Should -Be 'Dynamic'
                    $Result.TeamingMode            | Should -Be 'SwitchIndependent'
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_xNetworkTeam\Set-TargetResource' {
            $newTeam = [PSObject] @{
                Name                   = $testTeam.Name
                TeamMembers            = $testTeam.TeamMembers
                LoadBalancingAlgorithm = 'Dynamic'
                TeamingMode            = 'SwitchIndependent'
                Ensure                 = 'Present'
            }

            Context 'Team does not exist but should' {
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

            Context 'Team exists but needs a different teaming mode' {
                Mock -CommandName Get-NetLbfoTeam -MockWith { $mockTeam }
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

            Context 'Team exists but needs a different load balacing algorithm' {
                Mock -CommandName Get-NetLbfoTeam -MockWith { $mockTeam }
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

            Context 'Team exists but has to remove a member adapter' {
                Mock -CommandName Get-NetLbfoTeam -MockWith { $mockTeam }
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

            Context 'Team exists but has to add a member adapter' {
                Mock -CommandName Get-NetLbfoTeam -MockWith { $mockTeam }
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

            Context 'Team exists but should not exist' {
                Mock -CommandName Get-NetLbfoTeam -MockWith { $mockTeam }
                Mock -CommandName New-NetLbfoTeam
                Mock -CommandName Set-NetLbfoTeam
                Mock -CommandName Remove-NetLbfoTeam
                Mock -CommandName Remove-NetLbfoTeamMember
                Mock -CommandName Add-NetLbfoTeamMember

                It 'Should not throw error' {
                    {
                        $updateTeam = $newTeam.Clone()
                        $updateTeam.Ensure = 'absent'
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

        Describe 'MSFT_xNetworkTeam\Test-TargetResource' {
            $newTeam = [PSObject] @{
                Name                   = $testTeam.Name
                TeamMembers            = $testTeam.TeamMembers
                LoadBalancingAlgorithm = 'Dynamic'
                TeamingMode            = 'SwitchIndependent'
                Ensure                 = 'Present'
            }

            Context 'Team does not exist but should' {
                Mock -CommandName Get-NetLbfoTeam

                It 'Should return false' {
                    Test-TargetResource @newTeam | Should -Be $false
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }

            Context 'Team exists but needs a different teaming mode' {
                Mock -CommandName Get-NetLbfoTeam -MockWith { $mockTeam }

                It 'Should return false' {
                    $updateTeam = $newTeam.Clone()
                    $updateTeam.TeamingMode = 'LACP'
                    Test-TargetResource @updateTeam | Should -Be $false
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }

            Context 'team exists but needs a different load balacing algorithm' {
                Mock -CommandName Get-NetLbfoTeam -MockWith { $mockTeam }

                It 'Should return false' {
                    $updateTeam = $newTeam.Clone()
                    $updateTeam.LoadBalancingAlgorithm = 'HyperVPort'
                    Test-TargetResource @updateTeam | Should -Be $false
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }

            Context 'Team exists but has to remove a member adapter' {
                Mock -CommandName Get-NetLbfoTeam -MockWith { $mockTeam }

                It 'Should return false' {
                    $updateTeam = $newTeam.Clone()
                    $updateTeam.TeamMembers = $newTeam.TeamMembers[0]
                    Test-TargetResource @updateTeam | Should -Be $false
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }

            Context 'Team exists but has to add a member adapter' {
                Mock -CommandName Get-NetLbfoTeam -MockWith { $mockTeam }

                It 'Should return false' {
                    $updateTeam = $newTeam.Clone()
                    $updateTeam.TeamMembers += 'NIC3'
                    Test-TargetResource @updateTeam | Should -Be $false
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }

            Context 'Team exists but should not exist' {
                Mock -CommandName Get-NetLbfoTeam -MockWith { $mockTeam }

                It 'Should return $false' {
                    $updateTeam = $newTeam.Clone()
                    $updateTeam.Ensure = 'absent'
                    Test-TargetResource @updateTeam | Should -Be $false
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }

            Context 'Team exists and no action needed' {
                Mock -CommandName Get-NetLbfoTeam -MockWith { $mockTeam }

                It 'Should return true' {
                    $updateTeam = $newTeam.Clone()
                    Test-TargetResource @updateTeam | Should -Be $true
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }

            Context 'Team does not and no action needed' {
                Mock -CommandName Get-NetLbfoTeam

                It 'Should return true' {
                    $updateTeam = $newTeam.Clone()
                    $updateTeam.Ensure = 'Absent'
                    Test-TargetResource @updateTeam | Should -Be $true
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }
        }

    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
