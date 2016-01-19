$Global:DSCModuleName   = 'xNetworking'
$Global:DSCResourceName = 'NetworkTeam'

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
        $MockNetTeam = [PSCustomObject] @{
            Name                    = 'HostTeam'
        }

        $TestTeam = [PSObject]@{
            Name                    = $MockNetTeam.Name
            TeamMembers             = 'NIC1','NIC2'
        }

        $MockTeam = [PSObject]@{
            Name                    = $MockNetTeam.Name
            TeamMembers             = $TestTeam.TeamMembers
            loadBalancingAlgorithm  = 'Dynamic'
            teamingMode             = 'SwitchIndependent'
            Ensure                  = 'Present'
        }
    
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {

            Context 'Team does not exist' {
                Mock Get-NetLbfoTeam
                It 'should return ensure as absent' {
                    $Result = Get-TargetResource `
                        @TestTeam
                    $Result.Ensure | Should Be 'Absent'
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-NetLbfoTeam -Exactly 1
                } 
            }
    
            Context 'Network Team exists' {
                Mock Get-NetLbfoTeam -MockWith { $MockTeam }
                It 'should return team properties' {
                    $Result = Get-TargetResource `
                        @TestTeam
                    $Result.Ensure                 | Should Be 'Present'
                    $Result.Name                   | Should Be $TestTeam.Name
                    $Result.TeamMembers            | Should Be $TestTeam.TeamMembers
                    $Result.loadBalancingAlgorithm | Should Be 'Dynamic'
                    $Result.teamingMode            | Should Be 'SwitchIndependent'
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-NetLbfoTeam -Exactly 1
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
