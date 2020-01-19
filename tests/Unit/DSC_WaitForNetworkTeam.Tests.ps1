$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_WaitForNetworkTeam'

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
        $testTeamName = 'TestTeam'
        $mockedGetNetLbfoTeamUp = [pscustomobject] @{
            Name   = $testTeamName
            Status = 'Up'
        }
        $mockedGetNetLbfoTeamDegraded = [pscustomobject] @{
            Name   = $testTeamName
            Status = 'Degraded'
        }
        $testTeamParametersGet = @{
            Name    = $testTeamName
            Verbose = $true
        }
        $testTeamParameters = @{
            Name             = $testTeamName
            RetryIntervalSec = 5
            RetryCount       = 20
            Verbose          = $true
        }
        $getNetLbfoTeamStatusParameters = @{
            Name    = $testTeamName
            Verbose = $true
        }

        Describe 'DSC_WaitForVolume\Get-TargetResource' -Tag 'Get' {
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

        Describe 'DSC_WaitForVolume\Set-TargetResource' -Tag 'Set' {
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

        Describe 'DSC_WaitForVolume\Test-TargetResource' -Tag 'Test' {
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

        Describe 'DSC_WaitForVolume\Get-NetLbfoTeamStatus' {
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
    Invoke-TestCleanup
}
