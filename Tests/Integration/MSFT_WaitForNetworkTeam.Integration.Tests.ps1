<#
    These tests can not be run in AppVeyor as this will cause the network
    adapter to disconnect and terminate the build.

    They can only be run if two teaming compatible network adapters are
    present on the test machine and the adapters can be safely used in
    a team during the test process.

    Loopback adapters can not be used for NIC teaming and only server OS
    SKU machines will support it.

    To enable this test to be run, add the names of the adapters to use
    for testing into the $script:NetworkTeamMembers array below. E.g.
    $script:NetworkTeamMembers = @('Ethernet','Ethernet 2')
#>
$script:NetworkTeamMembers = @()
$script:DSCModuleName      = 'NetworkingDsc'
$script:DSCResourceName    = 'MSFT_WaitForNetworkTeam'

# Load the common test helper
Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

# Check if integration tests can be run
if (-not (Test-NetworkTeamIntegrationEnvironment -NetworkAdapters $script:NetworkTeamMembers))
{
    Write-Warning -Message 'Integration tests will be skipped.'
    return
}

#region HEADER
# Integration Test Template Version: 1.1.1
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
    -TestType Integration
#endregion

# Using try/finally to always cleanup even if something awful happens.
try
{
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    Describe "$($script:DSCResourceName)_Integration" {
        $null = New-NetLbfoTeam `
            -Name 'TestTeam' `
            -TeamMembers $script:NetworkTeamMembers `
            -LoadBalancingAlgorithm 'MacAddresses' `
            -TeamingMode 'SwitchIndependent' `
            -Confirm:$false

        $configurationData = @{
            AllNodes = @(
                @{
                    NodeName               = 'localhost'
                    Name                   = 'TestTeam'
                    RetryIntervalSec       = 2
                    RetryCount             = 30
                }
            )
        }

        Context 'When the network team has been created' {
            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:DSCResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configurationData

                    Start-DscConfiguration `
                        -Path $TestDrive `
                        -ComputerName localhost `
                        -Wait `
                        -Verbose `
                        -Force `
                        -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $result = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $result.Ensure                 | Should -Be $configurationData.AllNodes[0].Ensure
                $result.Name                   | Should -Be $configurationData.AllNodes[0].Name
            }
        }
    }
}
finally
{
    # Remove the team just in case it wasn't removed correctly
    Remove-NetLbfoTeam `
        -Name 'TestTeam' `
        -Confirm:$false `
        -ErrorAction SilentlyContinue

    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
