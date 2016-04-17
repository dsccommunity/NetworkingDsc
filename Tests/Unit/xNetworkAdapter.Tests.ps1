$Global:ModuleName = 'xNetworkAdapter'

#region HEADER
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}
else
{
    & git @('-C',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
Import-Module (Join-Path -Path $moduleRoot -ChildPath "$Global:ModuleName.psm1") -Force

#endregion

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $Global:ModuleName {
    
        # Create the Mock Objects that will be used for running tests
        $MockNetAdapter = [PSCustomObject] @{
            Name                    = 'Ethernet'
            PhysicalMediaType              = '802.3'
            Status                         = 'Up'
        }

        $MockHypervVmNetAdapter = [PSCustomObject] @{
            Name                    = 'Ethernet'
            PhysicalMediaType              = 'Unspecified'
            Status                         = 'Up'
        }
        
        $MockMultipleNetAdapter = @(
            [PSCustomObject] @{
                Name                    = 'Ethernet1'
                PhysicalMediaType              = '802.3'
                Status                         = 'Up'
            },
            [PSCustomObject] @{
                Name                    = 'MyEthernet'
                PhysicalMediaType              = '802.3'
                Status                         = 'Up'
            }
        )

        $TestAdapterKeys = @{
            Name                           = 'MyEthernet'
            PhysicalMediaType              = '802.3'
            Status                         = 'Up'
        } 

        $TestHypervVmAdapterKeys = @{
            Name                           = 'MyEthernet'
            Status                         = 'Up'
        } 
  
        Describe "$($Global:ModuleName)\Get-xNetworkAdapterName" {
    
            Context 'Adapter does not exist' {
                
                Mock Get-NetAdapter
    
                It 'should return absent Route' {
                    $Result = Get-xNetworkAdapterName @TestAdapterKeys
                    $Result.MatchingAdapterCount | Should Be 0
                    $Result.Name | Should Be $null
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                } 
            }
    
            Context 'Adapter does exist' {
                
                Mock Get-NetAdapter -MockWith { $MockNetAdapter }
    
                It 'should return correct Route' {
                    $Result = Get-xNetworkAdapterName @TestAdapterKeys
                    $Result.MatchingAdapterCount | Should Be 1
                    $Result.Name | Should Be 'Ethernet'
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                }
            }
            Context 'Hyperv VM Adapter does exist' {
                
                Mock Get-NetAdapter -MockWith { $MockHypervVmNetAdapter }
    
                It 'should return correct Route' {
                    $Result = Get-xNetworkAdapterName @TestHypervVmAdapterKeys
                    $Result.MatchingAdapterCount | Should Be 1
                    $Result.Name | Should Be 'Ethernet'
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                }
            }
            Context 'Multiple Adapters exist' {
                
                Mock Get-NetAdapter -MockWith { $MockMultipleNetAdapter }
    
                It 'should return correct Route' {
                    $Result = Get-xNetworkAdapterName `
                        @TestAdapterKeys
                    $Result.MatchingAdapterCount | Should Be 1
                    $Result.Name | Should Be 'MyEthernet'
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                }
            }
        }
    
        Describe "$($Global:ModuleName)\Set-xNetworkAdapterName" {
    
            Context 'Adapter does not exist' {
                
                Mock Get-NetAdapter
                Mock Rename-NetAdapter
    
                It 'should not throw error' {
                    { 
                        $Splat = $TestAdapterKeys.Clone()
                        Set-xNetworkAdapterName @Splat
                    } | Should Throw 'A NetAdapter matching the properties was not found. Please correct the properties and try again.'
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                    Assert-MockCalled -commandName Rename-NetAdapter -Exactly 0
                }
            }
    
            Context 'Adapter exists and should be renamed' {
                
                Mock Get-NetAdapter -MockWith { $MockNetAdapter }
                Mock Rename-NetAdapter
    
                It 'should not throw error' {
                    { 
                        $Splat = $TestAdapterKeys.Clone()
                        Set-xNetworkAdapterName @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                    Assert-MockCalled -commandName Rename-NetAdapter -Exactly 1
                }
            }
            Context 'Hyperv VM Adapter exists and should be renamed' {
                
                Mock Get-NetAdapter -MockWith { $MockHypervVmNetAdapter }
                Mock Rename-NetAdapter
    
                It 'should not throw error' {
                    { 
                        $Splat = $TestHypervVmAdapterKeys.Clone()
                        Set-xNetworkAdapterName @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                    Assert-MockCalled -commandName Rename-NetAdapter -Exactly 1
                }
            }
            Context 'Multiple matching adapter exists and IgnoreMultipleMatchingAdapters is true and name matches' {
                
                Mock Get-NetAdapter -MockWith { $MockMultipleNetAdapter }
                Mock Rename-NetAdapter
    
                It 'should not throw error' {
                    { 
                        $Splat = $TestAdapterKeys.Clone()
                        Set-xNetworkAdapterName @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                    Assert-MockCalled -commandName Rename-NetAdapter -Exactly 0
                }
            }
            Context 'Multiple matching adapter exists and IgnoreMultipleMatchingAdapters is true and name mismatches' {
                
                Mock Get-NetAdapter -MockWith { $MockMultipleNetAdapter }
                Mock Rename-NetAdapter
    
                It 'should not throw error' {
                    { 
                        $Splat = $TestAdapterKeys.Clone()
                        $Splat.Name = 'MyEthernet2'
                        $Splat.IgnoreMultipleMatchingAdapters = $true
                        Set-xNetworkAdapterName @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                    Assert-MockCalled -commandName Rename-NetAdapter -Exactly 1
                }
            }
            Context 'Multiple matching adapter exists and IgnoreMultipleMatchingAdapters is false' {
                
                Mock Get-NetAdapter -MockWith { $MockMultipleNetAdapter }
                Mock Rename-NetAdapter
    
                It 'should not throw error' {
                    { 
                        $Splat = $TestAdapterKeys.Clone()
                        $Splat.Name = 'MyEthernet2'
                        $Splat.IgnoreMultipleMatchingAdapters = $false
                        Set-xNetworkAdapterName @Splat
                    } | Should Throw 'Multiple matching NetAdapters where found for the properties. Please correct the properties or specify IgnoreMultipleMatchingAdapters to only use the first and try again.'                    
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                    Assert-MockCalled -commandName Rename-NetAdapter -Exactly 0
                }
            }        }
    
        Describe "$($Global:ModuleName)\Test-xNetworkAdapterName" {

            Context 'NetAdapter does not exist' {
                
                Mock Get-NetAdapter -MockWith { $MockNetAdapter }
    
                It 'should return false' {
                    $Splat = $TestAdapterKeys.Clone()
                    Test-xNetworkAdapterName @Splat | Should Be $False
                    
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                }
            }
    
            Context 'NetAdapter exists and should but renamed' {
                
                Mock Get-NetAdapter -MockWith { $MockNetAdapter }
    
                It 'should return false' {
                    { 
                       $Splat = $TestAdapterKeys.Clone()
                        Test-xNetworkAdapterName @Splat | Should Be $False
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                }
            }
    
        }

        Describe "$($Global:ModuleName)\Test-ResourceProperty" {
      
            Context 'TBD' {
  
            }
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    #endregion
}
