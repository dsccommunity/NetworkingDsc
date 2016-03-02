#Remove this following line before using this integration test script
return

$Global:DSCModuleName      = 'xNetworking'
$Global:DSCResourceName    = 'MSFT_xNetworkTeam'
$Global:teamMembers        = (Get-NetAdapter -Physical).Name

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
    -TestType Integration 
#endregion

# Using try/finally to always cleanup even if something awful happens.
try
{
    #region Integration Tests
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($Global:DSCResourceName).config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    Describe "$($Global:DSCResourceName)_Integration" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($Global:DSCResourceName)_Config -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            Start-Sleep -Seconds 30
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should have set the resource and all the parameters should match' {
            $result = Get-DscConfiguration | Where-Object {$_.ConfigurationName -eq "$($Global:DSCResourceName)_Config"}
            $result.Ensure                 | Should Be $TestTeam.Ensure
            $result.Name                   | Should Be $TestTeam.Name
            $result.TeamMembers            | Should Be $Global:teamMembers
            $result.loadBalancingAlgorithm | Should Be $TestTeam.loadBalancingAlgorithm
            $result.teamingMode            | Should Be $TestTeam.teamingMode
        }

        Remove-NetLbfoTeam `
            -Name $TestTeam.Name `
            -Confirm:$false
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
