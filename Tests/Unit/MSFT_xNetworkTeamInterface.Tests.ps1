$Global:DSCModuleName = 'xNetworking'
$Global:DSCResourceName = 'MSFT_xNetworkTeamInterface'

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
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $Global:DSCResourceName {
        # Create the Mock -CommandName Objects that will be used for running tests
        $mockNetTeamNic = [PSCustomObject] @{
            Name = 'HostTeamNic'
            Team = 'HostTeam'
        }

        $testTeamNic = [PSObject] @{
            Name     = $mockNetTeamNic.Name
            TeamName = $mockNetTeamNic.Team
            Verbose  = $true
        }

        $newTeamNic = [PSObject] @{
            Name     = $testTeamNic.Name
            TeamName = $testTeamNic.TeamName
            VlanId   = 100
            Verbose  = $true
        }

        $mockTeamNic = {
            [PSObject] @{
                Name   = $testTeamNic.Name
                Team   = $testTeamNic.TeamName
                VlanId = 100
            }
        }

        $mockTeamNicDefaultVLAN = {
            [PSObject] @{
                Name   = $testTeamNic.Name
                Team   = $testTeamNic.TeamName
                VlanId = $null
            }
        }

        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
            Context 'Team Interface does not exist' {
                Mock -CommandName Get-NetLbfoTeamNic

                It 'Should not throw exception' {
                    $script:result = Get-TargetResource @testTeamNic
                }

                It 'Should return ensure as absent' {
                    $script:result.Ensure | Should -Be 'Absent'
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeamNic -Exactly -Times 1
                }
            }

            Context 'Network Team Interface exists' {
                Mock -CommandName Get-NetLbfoTeamNic -MockWith $mockTeamNic

                It 'Should not throw exception' {
                    $script:result = Get-TargetResource @testTeamNic
                }

                It 'Should return team properties' {
                    $script:result.Ensure   | Should Be 'Present'
                    $script:result.Name     | Should Be $testTeamNic.Name
                    $script:result.TeamName | Should Be $testTeamNic.TeamName
                    $script:result.VlanId   | Should be 100
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeamNic -Exactly -Times 1
                }
            }
        }

        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            Context 'Team Interface does not exist but should' {
                Mock -CommandName Get-NetLbfoTeamNic
                Mock -CommandName Add-NetLbfoTeamNic
                Mock -CommandName Set-NetLbfoTeamNic

                It 'Should not throw exception' {
                    {
                        Set-TargetResource @newTeamNic
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeamNic -Exactly -Times 1
                    Assert-MockCalled -CommandName Add-NetLbfoTeamNic -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetLbfoTeamNic -Exactly -Times 0
                }
            }

            Context 'Team Interface exists but needs a different VlanId' {
                Mock -CommandName Get-NetLbfoTeamNic -MockWith $mockTeamNic
                Mock -CommandName Add-NetLbfoTeamNic
                Mock -CommandName Set-NetLbfoTeamNic

                It 'Should not throw exception' {
                    {
                        $updateTeamNic = $newTeamNic.Clone()
                        $updateTeamNic.VlanId = 105
                        Set-TargetResource @updateTeamNic
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeamNic -Exactly -Times 1
                    Assert-MockCalled -CommandName Add-NetLbfoTeamNic -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-NetLbfoTeamNic -Exactly -Times 1
                }
            }

            Context 'Team Interface exists but should not exist' {
                Mock -CommandName Get-NetLbfoTeamNic -MockWith $mockTeamNic
                Mock -CommandName Add-NetLbfoTeamNic
                Mock -CommandName Set-NetLbfoTeamNic
                Mock -CommandName Remove-NetLbfoTeamNic

                It 'Should not throw exception' {
                    {
                        $updateTeamNic = $newTeamNic.Clone()
                        $updateTeamNic.Ensure = 'absent'
                        Set-TargetResource @updateTeamNic
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeamNic -Exactly -Times 1
                    Assert-MockCalled -CommandName Add-NetLbfoTeamNic -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-NetLbfoTeamNic -Exactly -Times 0
                    Assert-MockCalled -CommandName Remove-NetLbfoTeamNic -Exactly -Times 1
                }
            }
        }

        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            Context 'Team Interface does not exist but should' {
                Mock -CommandName Get-NetLbfoTeamNic

                It 'Should not throw exception' {
                    {
                        $script:result = Test-TargetResource @newTeamNic
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeamNic -Exactly -Times 1
                }
            }

            Context 'Team Interface exists but needs a different VlanId' {
                Mock -CommandName Get-NetLbfoTeamNic -MockWith $mockTeamNic

                It 'Should not throw exception' {
                    $updateTeamNic = $newTeamNic.Clone()
                    $updateTeamNic.VlanId = 105
                    $script:result = Test-TargetResource @updateTeamNic
                }

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeamNic -Exactly -Times 1
                }
            }

            Context 'Team Interface exists but should not exist' {
                Mock -CommandName Get-NetLbfoTeamNic -MockWith $mockTeamNic

                It 'Should not throw exception' {
                    $updateTeamNic = $newTeamNic.Clone()
                    $updateTeamNic.Ensure = 'Absent'
                    $script:result = Test-TargetResource @updateTeamNic
                }

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeamNic -Exactly -Times 1
                }
            }

            Context 'Team Interface exists and no action needed' {
                Mock -CommandName Get-NetLbfoTeamNic -MockWith $mockTeamNic

                It 'Should not throw exception' {
                    $updateTeamNic = $newTeamNic.Clone()
                    $script:result = Test-TargetResource @updateTeamNic
                }

                It 'Should return true' {
                    $script:result | Should -Be $true
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeamNic -Exactly -Times 1
                }
            }

            Context 'Team Interface does not exist and no action needed' {
                Mock -CommandName Get-NetLbfoTeamNic

                It 'Should not throw exception' {
                    $updateTeamNic = $newTeamNic.Clone()
                    $updateTeamNic.Ensure = 'Absent'
                    $script:result = Test-TargetResource @updateTeamNic
                }

                It 'Should return true' {
                    $script:result | Should -Be $true
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeamNic -Exactly -Times 1
                }
            }

            Context 'Team Interface exists on the default 0 VLAN' {
                Mock -CommandName Get-NetLbfoTeamNic -MockWith $mockTeamNicDefaultVLAN

                It 'Should not throw exception' {
                    $TeamNicOnDefaultVLAN = $newTeamNic.Clone()
                    $TeamNicOnDefaultVLAN.VlanId = 0
                    $script:result = Test-TargetResource @TeamNicOnDefaultVLAN
                }

                It 'Should return true' {
                    $script:result | Should -Be $true
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeamNic -Exactly -Times 1
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
