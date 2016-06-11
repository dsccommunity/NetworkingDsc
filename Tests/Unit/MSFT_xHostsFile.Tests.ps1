$Global:DSCModuleName   = 'xNetworking'
$Global:DSCResourceName = 'MSFT_xHostsFile'

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
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit 
#endregion

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $Global:DSCResourceName {
        # Create the Mock Objects that will be used for running tests
        $MockHostEntry = [PSCustomObject] @{
            IPAddress           = '192.168.10.1'
            HostName             = 'Host01'
        }

        $HostEntry = [PSObject]@{
            IPAddress               = $MockHostEntry.IPAddress
            HostName                = $MockHostEntry.HostName
        }

        $HostEntryObject = [PSObject]@{
            IPAddress               = $HostEntry.IPAddress
            HostName                = $HostEntry.HostName
            Ensure                  = 'Present'
        }       
    
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {

            Context 'Hosts file entry does not exist' {
                Mock Test-HostEntry
                It 'should return ensure as absent' {
                    $Result = Get-TargetResource `
                        @HostEntry
                    $Result.Ensure | Should Be 'Absent'
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Test-HostEntry -Exactly 1
                } 
            }
    
            Context 'Hosts file entry exists' {
                Mock Test-HostEntry -MockWith { $true }
                It 'should return host entry' {
                    $Result = Get-TargetResource @HostEntry
                    $Result.Ensure                 | Should Be 'Present'
                    $Result.HostName               | Should Be $HostEntry.HostName
                    $Result.IPAddress              | Should Be $HostEntry.IPAddress
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Test-HostEntry  -Exactly 1
                }
            }
        }

        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            $newEntry = [PSObject]@{
                HostName                = $HostEntry.HostName
                IPAddress               = $HostEntry.IPAddress
                Ensure                  = 'Present'
            }

            Context 'hosts file entry does not exist but should' {
                Mock Add-HostEntry
                Mock Remove-HostEntry

                It 'should not throw error' {
                    { 
                        Set-TargetResource @newEntry
                    } | Should Not Throw
                }

                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Add-HostEntry -Exactly 1
                    Assert-MockCalled -commandName Remove-HostEntry -Exactly 0
                } 
            }
    
            Context 'hosts file exists but should not' {
                Mock Add-HostEntry
                Mock Remove-HostEntry

                It 'should not throw error' {
                    { 
                        $HostsEntry = $newEntry.Clone()
                        $HostsEntry.Ensure = 'Absent'
                        Set-TargetResource @HostsEntry
                    } | Should Not Throw
                }

                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Add-HostEntry -Exactly 0
                    Assert-MockCalled -commandName Remove-HostEntry -Exactly 1
                } 
            }
        }

        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            $newEntry = [PSObject]@{
                HostName                = $HostEntry.HostName
                IPAddress               = $HostEntry.IPAddress
                Ensure                  = 'Present'
            }
  
            Context 'hosts file entry does not exist but it should' {
                Mock Test-HostEntry -MockWith { $false }
    
                It 'should return false' {
                    Test-TargetResource @newEntry | Should be $false
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Test-HostEntry -Exactly 1
                }
            }

            Context 'hosts file entry exists but it should not' {
                Mock Test-HostEntry -MockWith { $true }
    
                It 'should return false' {
                    $HostsEntry = $newEntry.Clone()
                    $HostsEntry.Ensure = 'Absent'
                    Test-TargetResource @HostsEntry | Should Be $false
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Test-HostEntry -Exactly 1
                }
            }

            Context 'hosts file entry does not exist and it should not' {
                Mock Test-HostEntry -MockWith { $false }
    
                It 'should return false' {
                    $HostsEntry = $newEntry.Clone()
                    $HostsEntry.Ensure = 'Absent'
                    Test-TargetResource @HostsEntry | Should be $true
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Test-HostEntry -Exactly 1
                }
            }

            Context 'hosts file entry exists and it should' {
                Mock Test-HostEntry -MockWith { $true }
    
                It 'should return false' {
                    Test-TargetResource @newEntry | Should Be $true
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Test-HostEntry -Exactly 1
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
