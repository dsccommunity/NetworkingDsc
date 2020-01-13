$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_NetAdapterRdma'

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

        Describe 'DSC_NetAdapterRdma\Get-TargetResource' -Tag 'Get' {
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
                    $Result.Name | Should -Be $targetParameters.Name
                    $Result.Enabled | Should -Be $true
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                }
            }
        }

        Describe 'DSC_NetAdapterRdma\Set-TargetResource' -Tag 'Set' {
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

        Describe 'DSC_NetAdapterRdma\Test-TargetResource' -Tag 'Test' {
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
    Invoke-TestCleanup
}
