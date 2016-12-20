$script:DSCModuleName   = 'xNetworking'
$script:DSCResourceName = 'MSFT_xNetAdapterRDMA'

#region HEADER
if ( (-not (Test-Path -Path '.\DSCResource.Tests\')) -or `
     (-not (Test-Path -Path '.\DSCResource.Tests\TestHelper.psm1')) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git')
}
else
{
    & git @('-C',(Join-Path -Path (Get-Location) -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module .\DSCResource.Tests\TestHelper.psm1 -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit 
#endregion

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $script:DSCResourceName {
        # Create the Mock Objects that will be used for running tests
        $MockNetAdapterRDMA = [PSCustomObject] @{
            Name                = 'SMB1_1'
            Enabled             = $true
        }

        $TestAdapter = [PSObject]@{
            Name                    = $MockNetAdapterRDMA.Name
        }    
    
        Describe "$($script:DSCResourceName)\Get-TargetResource" {
            function Get-NetAdapterRdma { }
            Context 'Network adapter does not exist' {
                It 'should throw error' {
                    Mock Get-NetAdapterRdma -MockWith {
                        throw 'Network adapter not found'
                    }
                    { Get-TargetResource @TestAdapter } | should throw
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-NetAdapterRdma -Exactly 1
                } 
            }
    
            Context 'Network Team exists' {
                Mock Get-NetAdapterRdma -MockWith { $MockNetAdapterRDMA }
                It 'should return network adapter RDMA properties' {
                    $Result = Get-TargetResource @TestAdapter
                    $Result.Name                   | Should Be $TestAdapter.Name
                    $Result.Enabled                | Should Be $true
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-NetAdapterRdma -Exactly 1
                }
            }
        }

        Describe "$($script:DSCResourceName)\Set-TargetResource" {
            function Get-NetAdapterRdma { }
            function Set-NetAdapterRdma {
                param (
                    [String] $Name,
                    [Boolean] $Enabled = $true
                )
            }
  
            Context 'Net Adapter does not exist' {
                Mock Set-NetAdapterRdma
    
                It 'should throw error' { 
                    Mock Get-NetAdapterRdma -MockWith {
                        throw 'Network adapter not found'
                    }
                    $updateAdapter = $TestAdapter.Clone()
                    $updateAdapter['Enabled'] = $true
                    { Set-TargetResource @updateAdapter } | Should throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapterRdma -Exactly 1
                    Assert-MockCalled -commandName Set-NetAdapterRdma -Exactly 0
                }
            } 

            Context 'Net Adapter RDMA is already enabled and no action needed' {
                Mock Set-NetAdapterRdma
    
                It 'should not throw error' { 
                    Mock Get-NetAdapterRdma -MockWith { $MockNetAdapterRDMA }
                    $updateAdapter = $TestAdapter.Clone()
                    $updateAdapter['Enabled'] = $true
                    { Set-TargetResource @updateAdapter } | Should not throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapterRdma -Exactly 1
                    Assert-MockCalled -commandName Set-NetAdapterRdma -Exactly 0
                }
            } 

            Context 'Net Adapter RDMA is disabled and should be enabled' {
                Mock Set-NetAdapterRdma
    
                It 'should not throw error' { 
                    Mock Get-NetAdapterRdma -MockWith { 
                        $configuration = [PSCustomObject] @{
                            Name    = 'SMB1_1'
                            Enabled = $false
                        }
                        return $configuration 
                    }
                    $updateAdapter = $TestAdapter.Clone()
                    $updateAdapter['Enabled'] = $true
                    { Set-TargetResource @updateAdapter } | Should not throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapterRdma -Exactly 1
                    Assert-MockCalled -commandName Set-NetAdapterRdma -Exactly 1
                }
            }            

            Context 'Net Adapter RDMA is enabled and should be disabled' {
                Mock Set-NetAdapterRdma
    
                It 'should not throw error' { 
                    Mock Get-NetAdapterRdma -MockWith { 
                        $configuration = [PSCustomObject] @{
                            Name    = 'SMB1_1'
                            Enabled = $true
                        }
                        return $configuration 
                    }
                    $updateAdapter = $TestAdapter.Clone()
                    $updateAdapter['Enabled'] = $false
                    { Set-TargetResource @updateAdapter } | Should not throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapterRdma -Exactly 1
                    Assert-MockCalled -commandName Set-NetAdapterRdma -Exactly 1
                }
            }    

            Context 'Net Adapter RDMA is already disabled and no action needed' {
                Mock Set-NetAdapterRdma
    
                It 'should not throw error' { 
                    Mock Get-NetAdapterRdma -MockWith { 
                        $configuration = [PSCustomObject] @{
                            Name    = 'SMB1_1'
                            Enabled = $false
                        }
                        return $configuration 
                    }
                    $updateAdapter = $TestAdapter.Clone()
                    $updateAdapter['Enabled'] = $false
                    { Set-TargetResource @updateAdapter } | Should not throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapterRdma -Exactly 1
                    Assert-MockCalled -commandName Set-NetAdapterRdma -Exactly 0
                }
            }                 
        }

        Describe "$($script:DSCResourceName)\Test-TargetResource" {
            function Get-NetAdapterRdma { }
  
            Context 'Net Adapter does not exist' {    
                It 'should throw error' { 
                    Mock Get-NetAdapterRdma -MockWith {
                        throw 'Network adapter not found'
                    }
                    $updateAdapter = $TestAdapter.Clone()
                    $updateAdapter['Enabled'] = $true
                    { Test-TargetResource @updateAdapter } | Should throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapterRdma -Exactly 1
                }
            } 

            Context 'Net Adapter RDMA is already enabled and no action needed' {
                It 'should return true' { 
                    Mock Get-NetAdapterRdma -MockWith { $MockNetAdapterRDMA }
                    $updateAdapter = $TestAdapter.Clone()
                    $updateAdapter['Enabled'] = $true
                    Test-TargetResource @updateAdapter | Should be $true
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapterRdma -Exactly 1
                }
            } 

            Context 'Net Adapter RDMA is disabled and should be enabled' {
                It 'should return false' { 
                    Mock Get-NetAdapterRdma -MockWith { 
                        $configuration = [PSCustomObject] @{
                            Name    = 'SMB1_1'
                            Enabled = $false
                        }
                        return $configuration 
                    }
                    $updateAdapter = $TestAdapter.Clone()
                    $updateAdapter['Enabled'] = $true
                    Test-TargetResource @updateAdapter | Should be $false
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapterRdma -Exactly 1
                }
            }            

            Context 'Net Adapter RDMA is enabled and should be disabled' {    
                It 'should return false' { 
                    Mock Get-NetAdapterRdma -MockWith { 
                        $configuration = [PSCustomObject] @{
                            Name    = 'SMB1_1'
                            Enabled = $true
                        }
                        return $configuration 
                    }
                    $updateAdapter = $TestAdapter.Clone()
                    $updateAdapter['Enabled'] = $false
                    Test-TargetResource @updateAdapter | Should be $false
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapterRdma -Exactly 1
                }
            }    

            Context 'Net Adapter RDMA is already disabled and no action needed' {
                It 'should return true' { 
                    Mock Get-NetAdapterRdma -MockWith { 
                        $configuration = [PSCustomObject] @{
                            Name    = 'SMB1_1'
                            Enabled = $false
                        }
                        return $configuration 
                    }
                    $updateAdapter = $TestAdapter.Clone()
                    $updateAdapter['Enabled'] = $false
                    Test-TargetResource @updateAdapter | Should be $true
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapterRdma -Exactly 1
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
