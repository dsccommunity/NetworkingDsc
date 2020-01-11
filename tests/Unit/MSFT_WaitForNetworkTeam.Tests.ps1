$script:DSCModuleName      = 'NetworkingDsc'
$script:DSCResourceName    = 'MSFT_WaitForNetworkTeam'

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
        $testTeamName = 'TestTeam'
        $mockedGetNetLbfoTeamUp = [pscustomobject] @{
            Name      = $testTeamName
            Status    = 'Up'
        }
        $mockedGetNetLbfoTeamDegraded = [pscustomobject] @{
            Name      = $testTeamName
            Status    = 'Degraded'
        }
        $testTeamParametersGet = @{
            Name             = $testTeamName
            Verbose          = $true
        }
        $testTeamParameters = @{
            Name             = $testTeamName
            RetryIntervalSec = 5
            RetryCount       = 20
            Verbose          = $true
        }
        $getNetLbfoTeamStatusParameters = @{
            Name             = $testTeamName
            Verbose          = $true
        }

        Describe 'MSFT_WaitForVolume\Get-TargetResource' -Tag 'Get' {
            Context 'When the network team exists' {
                Mock `
                    -CommandName Get-NetLbfoTeamStatus `
                    -MockWith { 'Up' }

                It 'Should not throw exception' {
                    {
                        $script:result = Get-TargetResource @testTeamParametersGet
                    } | Should -Not -Throw
                }

                It "Should return Name $testTeamName" {
                    $script:result.Name | Should -Be $testTeamName
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-NetLbfoTeamStatus `
                        -Exactly `
                        -Times 1
                }
            }

            Context 'When the network team does not exist' {
                Mock `
                    -CommandName Get-NetLbfoTeamStatus `
                    -MockWith {
                        New-InvalidOperationException -Message $($script:localizedData.NetworkTeamNotFoundMessage -f $testTeamName)
                    }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetworkTeamNotFoundMessage -f $testTeamName)

                It 'Should throw exception' {
                    {
                        $script:result = Get-TargetResource @testTeamParametersGet
                    } | Should -Throw $errorRecord
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-NetLbfoTeamStatus `
                        -Exactly `
                        -Times 1
                }
            }
        }

        Describe 'MSFT_WaitForVolume\Set-TargetResource' -Tag 'Set' {
            Context 'When network team is Up' {
                Mock Start-Sleep
                Mock -CommandName Get-NetLbfoTeamStatus -MockWith { 'Up' }

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource @testTeamParameters
                    } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Start-Sleep -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-NetLbfoTeamStatus -Exactly -Times 1
                }
            }

            Context 'When network team is not Up' {
                Mock Start-Sleep
                Mock -CommandName Get-NetLbfoTeamStatus -MockWith { 'Degraded' }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message $($script:localizedData.NetworkTeamNotUpAfterError -f $testTeamName, $testTeamParameters.RetryCount)

                It 'Should throw VolumeNotFoundAfterError' {
                    {
                        Set-TargetResource @testTeamParameters
                    } | Should -Throw $errorRecord
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Start-Sleep -Exactly -Times $testTeamParameters.RetryCount
                    Assert-MockCalled -CommandName Get-NetLbfoTeamStatus -Exactly -Times $testTeamParameters.RetryCount
                }
            }
        }

        Describe 'MSFT_WaitForVolume\Test-TargetResource' -Tag 'Test' {
            Context 'When network team is Up' {
                Mock -CommandName Get-NetLbfoTeamStatus -MockWith { 'Up' }

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource @testTeamParameters
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeamStatus -Exactly -Times 1
                }
            }

            Context 'When network team is not Up' {
                Mock -CommandName Get-NetLbfoTeamStatus -MockWith { 'Degraded' }

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource @testTeamParameters
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeamStatus -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_WaitForVolume\Get-NetLbfoTeamStatus' {
            Context 'When network team exists and is Up' {
                Mock -CommandName Get-NetLbfoTeam -MockWith { $mockedGetNetLbfoTeamUp }

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-NetLbfoTeamStatus @getNetLbfoTeamStatusParameters
                    } | Should -Not -Throw
                }

                It 'Should return "Up"' {
                    $script:result | Should -Be 'Up'
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }

            Context 'When network team exists and is Degraded' {
                Mock -CommandName Get-NetLbfoTeam -MockWith { $mockedGetNetLbfoTeamDegraded }

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-NetLbfoTeamStatus @getNetLbfoTeamStatusParameters
                    } | Should -Not -Throw
                }

                It 'Should return "Degraded"' {
                    $script:result | Should -Be 'Degraded'
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
                }
            }

            Context 'When network team does not exist' {
                Mock `
                    -CommandName Get-NetLbfoTeam `
                    -MockWith { Throw (New-Object -TypeName 'Microsoft.PowerShell.Cmdletization.Cim.CimJobException') }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetworkTeamNotFoundMessage -f $testTeamName)

                It 'Should throw expected exception' {
                    {
                        $script:result = Get-NetLbfoTeamStatus @getNetLbfoTeamStatusParameters
                    } | Should -Throw $errorRecord
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetLbfoTeam -Exactly -Times 1
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
