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
$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_NetworkTeam'

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
    Describe 'NetworkTeamInterface Integration Tests' {
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile -Verbose -ErrorAction Stop

        Describe "$($script:dscResourceName)_Integration" {
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
                        $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
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
                        $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
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

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
