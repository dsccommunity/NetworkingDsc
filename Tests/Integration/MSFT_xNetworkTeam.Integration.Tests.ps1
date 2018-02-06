<#
    These tests can not be run in AppVeyor as this will cause the network
    adapter to disconnect and terminate the build.

    They can be run by commenting out the return below. All the physical
    adapters in the machine will be used to create the team. The team will
    be removed when tests are complete.

    Loopback adapters can not be used for NIC teaming and only server OS
    SKU machines will support it.
#>
return

$script:DSCModuleName = 'xNetworking'
$script:DSCResourceName = 'MSFT_xNetworkTeam'

#region HEADER
# Integration Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xNetworking'

if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
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
        $teamMembers = (Get-NetAdapter -Physical).Name

        $configurationData = @{
            AllNodes = @(
                @{
                    NodeName               = 'localhost'
                    Name                   = 'TestTeam'
                    Members                = $teamMembers
                    LoadBalancingAlgorithm = 'MacAddresses'
                    TeamingMode            = 'SwitchIndependent'
                    Ensure                 = 'Present'
                }
            )
        }

        Context 'When the network team is created' {
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

                    # Wait for up to 60 seconds for the team to be created
                    $count = 0
                    While (-not (Get-NetLbfoTeam -Name 'TestTeam' -ErrorAction SilentlyContinue))
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
                $result = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $result.Ensure                 | Should -Be $configurationData.AllNodes[0].Ensure
                $result.Name                   | Should -Be $configurationData.AllNodes[0].Name
                $result.TeamMembers            | Should -Be $configurationData.AllNodes[0].Members
                $result.LoadBalancingAlgorithm | Should -Be $configurationData.AllNodes[0].LoadBalancingAlgorithm
                $result.TeamingMode            | Should -Be $configurationData.AllNodes[0].TeamingMode
            }
        }

        $configurationData.AllNodes[0].Ensure = 'Absent'

        Context 'When the network team is deleted' {
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

                    # Wait for up to 60 seconds for the team to be removed
                    $count = 0
                    While (Get-NetLbfoTeam -Name 'TestTeam' -ErrorAction SilentlyContinue)
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
                $result = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $result.Ensure                 | Should -Be $configurationData.AllNodes[0].Ensure
                $result.Name                   | Should -Be $configurationData.AllNodes[0].Name
                $result.TeamMembers            | Should -Be $configurationData.AllNodes[0].Members
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
