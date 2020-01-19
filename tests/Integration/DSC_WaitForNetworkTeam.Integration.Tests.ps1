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
$script:dscModuleName      = 'NetworkingDsc'
$script:dscResourceName    = 'DSC_WaitForNetworkTeam'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

# Check if integration tests can be run
if (-not (Test-NetworkTeamIntegrationEnvironment -NetworkAdapters $script:NetworkTeamMembers))
{
    Write-Warning -Message 'Integration tests will be skipped.'
    return
}

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
    -TestType 'Integration'

# Begin Testing
try
{
    Describe 'WaitForNetworkTeam Integration Tests' {
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile -Verbose -ErrorAction Stop

        Describe "$($script:dscResourceName)_Integration" {
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
                        & "$($script:dscResourceName)_Config" `
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
                        $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                    }
                    $result.Ensure                 | Should -Be $configurationData.AllNodes[0].Ensure
                    $result.Name                   | Should -Be $configurationData.AllNodes[0].Name
                }
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

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
