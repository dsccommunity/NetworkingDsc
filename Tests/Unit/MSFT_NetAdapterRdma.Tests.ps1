$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_NetAdapterRdma'

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
        $testAdapterName = 'SMB1_1'
        $targetParameters = [PSObject] @{
            Name = $testAdapterName
        }

        $mockNetAdapterRdmaEnabled = [PSCustomObject] @{
            Name    = $testAdapterName
            Enabled = $true
        }

        $mockNetAdapterRdmaDisabled = [PSCustomObject] @{
            Name    = $testAdapterName
            Enabled = $false
        }

        Describe 'MSFT_NetAdapterRdma\Get-TargetResource' -Tag 'Get' {
            function Get-NetAdapterRdma
            {
            }

            Context 'Network adapter does not exist' {
                Mock -CommandName Get-NetAdapterRdma -MockWith {
                    throw 'Network adapter not found'
                }

                It 'Should throw expected exception' {
                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.NetAdapterNotFoundError -f $testAdapterName)

                    {
                        Get-TargetResource @targetParameters
                    } | Should -Throw $errorRecord
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                }
            }

            Context 'Network Team exists' {
                Mock -CommandName Get-NetAdapterRdma -MockWith { $mockNetAdapterRdmaEnabled }

                It 'Should return network adapter RDMA properties' {
                    $Result = Get-TargetResource @targetParameters
                    $Result.Name                   | Should -Be $targetParameters.Name
                    $Result.Enabled                | Should -Be $true
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_NetAdapterRdma\Set-TargetResource' -Tag 'Set' {
            function Get-NetAdapterRdma
            {
            }
            function Set-NetAdapterRdma
            {
                param
                (
                    [Parameter(Mandatory = $true)]
                    [System.String]
                    $Name,

                    [Parameter(Mandatory = $true)]
                    [System.Boolean]
                    $Enabled = $true
                )
            }

            Context 'Net Adapter does not exist' {
                Mock -CommandName Set-NetAdapterRdma
                Mock -CommandName Get-NetAdapterRdma -MockWith {
                    throw 'Network adapter not found'
                }

                It 'Should throw expected exception' {
                    $setTargetResourceParameters = $targetParameters.Clone()
                    $setTargetResourceParameters['Enabled'] = $true

                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.NetAdapterNotFoundError -f $testAdapterName)

                    {
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Throw $errorRecord
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetAdapterRdma -Exactly -Times 0
                }
            }

            Context 'Net Adapter RDMA is already enabled and no action needed' {
                Mock -CommandName Set-NetAdapterRdma
                Mock -CommandName Get-NetAdapterRdma -MockWith { $mockNetAdapterRdmaEnabled }

                It 'Should not throw exception' {
                    $setTargetResourceParameters = $targetParameters.Clone()
                    $setTargetResourceParameters['Enabled'] = $true
                    {
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetAdapterRdma -Exactly -Times 0
                }
            }

            Context 'Net Adapter RDMA is disabled and should be enabled' {
                Mock -CommandName Set-NetAdapterRdma
                Mock -CommandName Get-NetAdapterRdma -MockWith { $mockNetAdapterRdmaDisabled }

                It 'Should not throw exception' {
                    $setTargetResourceParameters = $targetParameters.Clone()
                    $setTargetResourceParameters['Enabled'] = $true
                    {
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetAdapterRdma -Exactly -Times 1
                }
            }

            Context 'Net Adapter RDMA is enabled and should be disabled' {
                Mock -CommandName Set-NetAdapterRdma
                Mock -CommandName Get-NetAdapterRdma -MockWith { $mockNetAdapterRdmaEnabled }

                It 'Should not throw exception' {
                    $setTargetResourceParameters = $targetParameters.Clone()
                    $setTargetResourceParameters['Enabled'] = $false
                    {
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetAdapterRdma -Exactly -Times 1
                }
            }

            Context 'Net Adapter RDMA is already disabled and no action needed' {
                Mock -CommandName Set-NetAdapterRdma
                Mock -CommandName Get-NetAdapterRdma -MockWith { $mockNetAdapterRdmaDisabled }

                It 'Should not throw exception' {
                    $setTargetResourceParameters = $targetParameters.Clone()
                    $setTargetResourceParameters['Enabled'] = $false
                    {
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetAdapterRdma -Exactly -Times 0
                }
            }
        }

        Describe 'MSFT_NetAdapterRdma\Test-TargetResource' -Tag 'Test' {
            function Get-NetAdapterRdma
            {
            }

            Context 'Net Adapter does not exist' {
                Mock -CommandName Get-NetAdapterRdma -MockWith {
                    throw 'Network adapter not found'
                }

                It 'Should throw expected exception' {
                    $testTargetResourceParameters = $targetParameters.Clone()
                    $testTargetResourceParameters['Enabled'] = $true

                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.NetAdapterNotFoundError -f $testAdapterName)

                    {
                        Test-TargetResource @testTargetResourceParameters
                    } | Should -Throw $errorRecord
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                }
            }

            Context 'Net Adapter RDMA is already enabled and no action needed' {
                Mock -CommandName Get-NetAdapterRdma -MockWith { $mockNetAdapterRdmaEnabled }

                It 'Should return true' {
                    $testTargetResourceParameters = $targetParameters.Clone()
                    $testTargetResourceParameters['Enabled'] = $true
                    Test-TargetResource @testTargetResourceParameters | Should -Be $true
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                }
            }

            Context 'Net Adapter RDMA is disabled and should be enabled' {
                Mock -CommandName Get-NetAdapterRdma -MockWith { $mockNetAdapterRdmaDisabled }

                It 'Should return false' {
                    $testTargetResourceParameters = $targetParameters.Clone()
                    $testTargetResourceParameters['Enabled'] = $true
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                }
            }

            Context 'Net Adapter RDMA is enabled and should be disabled' {
                Mock -CommandName Get-NetAdapterRdma -MockWith { $mockNetAdapterRdmaEnabled }

                It 'Should return false' {
                    $testTargetResourceParameters = $targetParameters.Clone()
                    $testTargetResourceParameters['Enabled'] = $false
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                }
            }

            Context 'Net Adapter RDMA is already disabled and no action needed' {
                Mock -CommandName Get-NetAdapterRdma -MockWith { $mockNetAdapterRdmaDisabled }

                It 'Should return true' {
                    $testTargetResourceParameters = $targetParameters.Clone()
                    $testTargetResourceParameters['Enabled'] = $false
                    Test-TargetResource @testTargetResourceParameters | Should -Be $true
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
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
