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
$script:DSCResourceName    = 'MSFT_NetworkTeamInterface'

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
    #region Integration Tests
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    Describe "$($script:DSCResourceName)_Integration" {
        $configurationData = @{
            AllNodes = @(
                @{
                    NodeName               = 'localhost'
                    TeamName               = 'TestTeam'
                    Members                = $script:NetworkTeamMembers
                    LoadBalancingAlgorithm = 'MacAddresses'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                    InterfaceName          = 'TestInterface'
                    VlanId                 = 100
                }
            )
        }

        Context 'When the network team is created and the TestInterface is added' {
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

                    # Wait for up to 60 seconds for the team interface to be created
                    $count = 0
                    While (-not (Get-NetLbfoTeamNic -Name 'TestInterface' -Team 'TestTeam' -ErrorAction SilentlyContinue))
                    {
                        Start-Sleep -Seconds 1

                        if ($count -ge 60)
                        {
                            break
                        }

                        $count++
                    }
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $result = Get-DscConfiguration    | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $result[0].Ensure                 | Should -Be 'Present'
                $result[0].Name                   | Should -Be $configurationData.AllNodes[0].TeamName
                $result[0].TeamMembers            | Should -Be $configurationData.AllNodes[0].Members
                $result[0].LoadBalancingAlgorithm | Should -Be $configurationData.AllNodes[0].LoadBalancingAlgorithm
                $result[0].TeamingMode            | Should -Be $configurationData.AllNodes[0].TeamingMode
                $result[1].Ensure                 | Should -Be $configurationData.AllNodes[0].Ensure
                $result[1].Name                   | Should -Be $configurationData.AllNodes[0].InterfaceName
                $result[1].TeamName               | Should -Be $configurationData.AllNodes[0].TeamName
                $result[1].VlanId                 | Should -Be $configurationData.AllNodes[0].VlanId
            }
        }

        $configurationData.AllNodes[0].Ensure = 'Absent'

        Context 'When the network team is created and the TestInterface is removed' {
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

                    # Wait for up to 60 seconds for the team interface to be created
                    $count = 0
                    While (Get-NetLbfoTeamNic -Name 'TestInterface' -Team 'TestTeam' -ErrorAction SilentlyContinue)
                    {
                        Start-Sleep -Seconds 1

                        if ($count -ge 60)
                        {
                            break
                        }

                        $count++
                    }
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $result = Get-DscConfiguration    | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $result[0].Ensure                 | Should -Be 'Present'
                $result[0].Name                   | Should -Be $configurationData.AllNodes[0].TeamName
                $result[0].TeamMembers            | Should -Be $configurationData.AllNodes[0].Members
                $result[0].LoadBalancingAlgorithm | Should -Be $configurationData.AllNodes[0].LoadBalancingAlgorithm
                $result[0].TeamingMode            | Should -Be $configurationData.AllNodes[0].TeamingMode
                $result[1].Ensure                 | Should -Be $configurationData.AllNodes[0].Ensure
                $result[1].Name                   | Should -Be $configurationData.AllNodes[0].InterfaceName
                $result[1].TeamName               | Should -Be $configurationData.AllNodes[0].TeamName
            }
        }
    }
}
finally
{
    # Remove the team just in case it wasn't removed correctly
    Remove-NetLbfoTeamNic `
        -Team 'TestTeam' `
        -VlanId 100 `
        -Confirm:$false `
        -ErrorAction SilentlyContinue

    Remove-NetLbfoTeam `
        -Name 'TestTeam' `
        -Confirm:$false `
        -ErrorAction SilentlyContinue

    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
