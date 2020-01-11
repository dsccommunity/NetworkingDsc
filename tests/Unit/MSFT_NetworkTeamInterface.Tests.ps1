$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_NetworkTeamInterface'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
[System.String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    InModuleScope $script:DSCResourceName {
        # Create the Mock -CommandName Objects that will be used for running tests
        $script:testNicName = 'HostTeamNic'
        $script:testTeamName = 'HostTeam'

        $mockNetTeamNic = [PSCustomObject] @{
            Name = $script:testNicName
            Team = $script:testTeamName
        }

        $testTeamNic = [PSObject] @{
            Name     = $script:testNicName
            TeamName = $script:testTeamName
            Verbose  = $true
        }

        $newTeamNic = [PSObject] @{
            Name     = $script:testNicName
            TeamName = $script:testTeamName
            VlanId   = 100
            Verbose  = $true
        }

        $mockTeamNic = {
            [PSObject] @{
                Name   = $script:testNicName
                Team   = $script:testTeamName
                VlanId = 100
            }
        }

        $mockTeamNicDefaultVLAN = {
            [PSObject] @{
                Name   = $script:testNicName
                Team   = $script:testTeamName
                VlanId = $null
            }
        }

        $getNetLbfoTeamNic_ParameterFilter = {
            $Name -eq $script:testNicName `
            -and $Team -eq $script:testTeamName
        }

        $addNetLbfoTeamNic_ParameterFilter = {
            $Name -eq $script:testNicName `
            -and $Team -eq $script:testTeamName `
            -and $VlanId -eq 100
        }

        $setNetLbfoTeamNic_ParameterFilter = {
            $Name -eq $script:testNicName `
            -and $Team -eq $script:testTeamName `
            -and $VlanId -eq 105
        }

        $removeNetLbfoTeamNic_ParameterFilter = {
            $Team -eq $script:testTeamName `
            -and $VlanId -eq 100
        }

        Describe 'MSFT_NetworkTeamInterface\Get-TargetResource' -Tag 'Get' {
            Context 'When team Interface does not exist' {
                Mock `
                    -CommandName Get-NetLbfoTeamNic `
                    -ParameterFilter $getNetLbfoTeamNic_ParameterFilter

                It 'Should not throw exception' {
                    $script:result = Get-TargetResource @testTeamNic
                }

                It 'Should return ensure as absent' {
                    $script:result.Ensure | Should -Be 'Absent'
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-NetLbfoTeamNic `
                        -ParameterFilter $getNetLbfoTeamNic_ParameterFilter `
                        -Exactly -Times 1
                }
            }

            Context 'Network Team Interface exists' {
                Mock `
                    -CommandName Get-NetLbfoTeamNic `
                    -MockWith $mockTeamNic `
                    -ParameterFilter $getNetLbfoTeamNic_ParameterFilter

                It 'Should not throw exception' {
                    $script:result = Get-TargetResource @testTeamNic
                }

                It 'Should return team properties' {
                    $script:result.Ensure   | Should -Be 'Present'
                    $script:result.Name     | Should -Be $testTeamNic.Name
                    $script:result.TeamName | Should -Be $testTeamNic.TeamName
                    $script:result.VlanId   | Should -Be 100
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-NetLbfoTeamNic `
                        -ParameterFilter $getNetLbfoTeamNic_ParameterFilter `
                        -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_NetworkTeamInterface\Set-TargetResource' -Tag 'Set' {
            Context 'When team Interface does not exist but invalid VlanId (0) is passed' {
                Mock `
                    -CommandName Get-NetLbfoTeamNic `
                    -ParameterFilter $getNetLbfoTeamNic_ParameterFilter

                Mock -CommandName Add-NetLbfoTeamNic
                Mock -CommandName Set-NetLbfoTeamNic

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.FailedToCreateTeamNic)

                It 'Should not throw exception' {
                    {
                        $errorTeamNic = $newTeamNic.Clone()
                        $errorTeamNic.VlanId = 0
                        Set-TargetResource @errorTeamNic
                    } | Should -Throw $errorRecord
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled `
                        -CommandName Get-NetLbfoTeamNic `
                        -ParameterFilter $getNetLbfoTeamNic_ParameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Add-NetLbfoTeamNic `
                        -Exactly -Times 0

                    Assert-MockCalled `
                        -CommandName Set-NetLbfoTeamNic `
                        -Exactly -Times 0
                }
            }

            Context 'When team Interface does not exist but should' {
                Mock `
                    -CommandName Get-NetLbfoTeamNic `
                    -ParameterFilter $getNetLbfoTeamNic_ParameterFilter

                Mock `
                    -CommandName Add-NetLbfoTeamNic `
                    -ParameterFilter $addNetLbfoTeamNic_ParameterFilter

                Mock -CommandName Set-NetLbfoTeamNic

                It 'Should not throw exception' {
                    {
                        Set-TargetResource @newTeamNic
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled `
                        -CommandName Get-NetLbfoTeamNic `
                        -ParameterFilter $getNetLbfoTeamNic_ParameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Add-NetLbfoTeamNic `
                        -ParameterFilter $addNetLbfoTeamNic_ParameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Set-NetLbfoTeamNic `
                        -Exactly -Times 0
                }
            }

            Context 'When team Interface exists but needs a different VlanId' {
                Mock `
                    -CommandName Get-NetLbfoTeamNic `
                    -ParameterFilter $getNetLbfoTeamNic_ParameterFilter `
                    -MockWith $mockTeamNic

                Mock -CommandName Add-NetLbfoTeamNic

                Mock `
                    -CommandName Set-NetLbfoTeamNic  `
                    -ParameterFilter $setNetLbfoTeamNic_ParameterFilter

                It 'Should not throw exception' {
                    {
                        $updateTeamNic = $newTeamNic.Clone()
                        $updateTeamNic.VlanId = 105
                        Set-TargetResource @updateTeamNic
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled `
                        -CommandName Get-NetLbfoTeamNic `
                        -ParameterFilter $getNetLbfoTeamNic_ParameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Add-NetLbfoTeamNic `
                        -Exactly -Times 0

                    Assert-MockCalled `
                        -CommandName Set-NetLbfoTeamNic `
                        -ParameterFilter $setNetLbfoTeamNic_ParameterFilter `
                        -Exactly -Times 1
                }
            }

            Context 'When team Interface exists but should not exist' {
                Mock `
                    -CommandName Get-NetLbfoTeamNic `
                    -ParameterFilter $getNetLbfoTeamNic_ParameterFilter `
                    -MockWith $mockTeamNic

                Mock -CommandName Add-NetLbfoTeamNic
                Mock -CommandName Set-NetLbfoTeamNic

                Mock `
                    -CommandName Remove-NetLbfoTeamNic `
                    -ParameterFilter $removeNetLbfoTeamNic_ParameterFilter

                It 'Should not throw exception' {
                    {
                        $updateTeamNic = $newTeamNic.Clone()
                        $updateTeamNic.Ensure = 'Absent'
                        Set-TargetResource @updateTeamNic
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled `
                        -CommandName Get-NetLbfoTeamNic `
                        -ParameterFilter $getNetLbfoTeamNic_ParameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Add-NetLbfoTeamNic `
                        -Exactly -Times 0

                    Assert-MockCalled `
                        -CommandName Set-NetLbfoTeamNic `
                        -Exactly -Times 0

                    Assert-MockCalled `
                        -CommandName Remove-NetLbfoTeamNic  `
                        -ParameterFilter $removeNetLbfoTeamNic_ParameterFilter `
                        -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_NetworkTeamInterface\Test-TargetResource' -Tag 'Test' {
            Context 'When team Interface does not exist but should' {
                Mock `
                    -CommandName Get-NetLbfoTeamNic `
                    -ParameterFilter $getNetLbfoTeamNic_ParameterFilter

                It 'Should not throw exception' {
                    {
                        $script:result = Test-TargetResource @newTeamNic
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled `
                        -CommandName Get-NetLbfoTeamNic `
                        -ParameterFilter $getNetLbfoTeamNic_ParameterFilter `
                        -Exactly -Times 1
                }
            }

            Context 'When team Interface exists but needs a different VlanId' {
                Mock `
                    -CommandName Get-NetLbfoTeamNic `
                    -ParameterFilter $getNetLbfoTeamNic_ParameterFilter `
                    -MockWith $mockTeamNic

                It 'Should not throw exception' {
                    $updateTeamNic = $newTeamNic.Clone()
                    $updateTeamNic.VlanId = 105
                    $script:result = Test-TargetResource @updateTeamNic
                }

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled `
                        -CommandName Get-NetLbfoTeamNic  `
                        -ParameterFilter $getNetLbfoTeamNic_ParameterFilter `
                        -Exactly -Times 1
                }
            }

            Context 'When team Interface exists but should not exist' {
                Mock `
                    -CommandName Get-NetLbfoTeamNic `
                    -ParameterFilter $getNetLbfoTeamNic_ParameterFilter `
                    -MockWith $mockTeamNic

                It 'Should not throw exception' {
                    $updateTeamNic = $newTeamNic.Clone()
                    $updateTeamNic.Ensure = 'Absent'
                    $script:result = Test-TargetResource @updateTeamNic
                }

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled `
                        -CommandName Get-NetLbfoTeamNic `
                        -ParameterFilter $getNetLbfoTeamNic_ParameterFilter `
                        -Exactly -Times 1
                }
            }

            Context 'When team Interface exists and no action needed' {
                Mock `
                    -CommandName Get-NetLbfoTeamNic `
                    -ParameterFilter $getNetLbfoTeamNic_ParameterFilter `
                    -MockWith $mockTeamNic

                It 'Should not throw exception' {
                    $updateTeamNic = $newTeamNic.Clone()
                    $script:result = Test-TargetResource @updateTeamNic
                }

                It 'Should return true' {
                    $script:result | Should -Be $true
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled `
                        -CommandName Get-NetLbfoTeamNic `
                        -ParameterFilter $getNetLbfoTeamNic_ParameterFilter `
                        -Exactly -Times 1
                }
            }

            Context 'When team Interface does not exist and no action needed' {
                Mock `
                    -CommandName Get-NetLbfoTeamNic `
                    -ParameterFilter $getNetLbfoTeamNic_ParameterFilter

                It 'Should not throw exception' {
                    $updateTeamNic = $newTeamNic.Clone()
                    $updateTeamNic.Ensure = 'Absent'
                    $script:result = Test-TargetResource @updateTeamNic
                }

                It 'Should return true' {
                    $script:result | Should -Be $true
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled `
                        -CommandName Get-NetLbfoTeamNic `
                        -ParameterFilter $getNetLbfoTeamNic_ParameterFilter `
                        -Exactly -Times 1
                }
            }

            Context 'When team Interface exists on the default 0 VLAN' {
                Mock `
                    -CommandName Get-NetLbfoTeamNic `
                    -ParameterFilter $getNetLbfoTeamNic_ParameterFilter `
                    -MockWith $mockTeamNicDefaultVLAN

                It 'Should not throw exception' {
                    $TeamNicOnDefaultVLAN = $newTeamNic.Clone()
                    $TeamNicOnDefaultVLAN.VlanId = 0
                    $script:result = Test-TargetResource @TeamNicOnDefaultVLAN
                }

                It 'Should return true' {
                    $script:result | Should -Be $true
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled `
                        -CommandName Get-NetLbfoTeamNic `
                        -ParameterFilter $getNetLbfoTeamNic_ParameterFilter `
                        -Exactly -Times 1
                }
            }
        }
    }
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
