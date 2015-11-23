$DSCModuleName      = 'xNetworking'
$DSCResourceName    = 'MSFT_xNetConnectionProfile'

#region HEADER
if ( (-not (Test-Path -Path '.\DSCResource.Tests\')) -or `
     (-not (Test-Path -Path '.\DSCResource.Tests\TestHelper.psm1')) )
{
    Throw @(
        "The DSCResource.Tests folder could not be found in the root folder of the $DSCModuleName DSC Module to test."
        "Please use Git to clone this repository to the root folder of the $DSCModuleName DSC Module that needs to be tested using the command:"
        "git clone https://github.com/PowerShell/DscResource.Tests.git"
    ) -join "`n"
}
Import-Module .\DSCResource.Tests\TestHelper.psm1 -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $DSCModuleName `
    -DSCResourceName $DSCResourceName `
    -TestType Integration 
#endregion

# Using try/finally to always cleanup even if something awful happens.
try
{
    #region Integration Tests
    <#
      This file exists so we can load the test file without necessarily having xNetworking in
      the $env:PSModulePath. Otherwise PowerShell will throw an error when reading the Pester File.
    #>
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$DSCResourceName.config.ps1"
    . $ConfigFile

    Describe "$($DSCResourceName)_Integration" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                [System.Environment]::SetEnvironmentVariable('PSModulePath',
                    $env:PSModulePath,[System.EnvironmentVariableTarget]::Machine)
                Invoke-Expression -Command "$($DSCResourceName)_Config -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path (Join-Path -Path $env:Temp -ChildPath $DSCResourceName) `
                    -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object {$_.ConfigurationName -eq 'MSFT_xNetconnectionProfile_Config'}
            $rule.InterfaceAlias   | Should Be $current.InterfaceAlias
            $rule.NetworkCategory  | Should Be $current.NetworkCategory
            $rule.IPv4Connectivity | Should Be $current.IPv4Connectivity
            $rule.IPv6Connectivity | Should Be $current.IPv6Connectivity
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
