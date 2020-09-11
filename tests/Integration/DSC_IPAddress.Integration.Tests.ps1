$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_IPAddress'

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

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

# Begin Testing
try
{
    Describe 'IPAddress Integration Tests' {
        # Configure loopback adapters
        New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA'
        New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA2'

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile -Verbose -ErrorAction Stop

        Describe "$($script:dscResourceName)_Integration" {
            Context 'When a single IP address is specified' {
                It 'Should compile and apply the MOF without throwing' {
                    {
                        # This is to pass to the Config
                        $configData = @{
                            AllNodes = @(
                                @{
                                    NodeName       = 'localhost'
                                    InterfaceAlias = 'NetworkingDscLBA'
                                    AddressFamily  = 'IPv4'
                                    IPAddress      = '10.11.12.13/16'
                                }
                            )
                        }

                        & "$($script:dscResourceName)_Config" `
                            -OutputPath $TestDrive `
                            -ConfigurationData $configData

                        Start-DscConfiguration `
                            -Path $TestDrive `
                            -ComputerName localhost `
                            -Wait `
                            -Verbose `
                            -Force `
                            -ErrorAction Stop
                    } | Should -Not -Throw
                }

                It 'should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should have set the resource and all the parameters should match' {
                    $current = Get-DscConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                    }
                    $current.InterfaceAlias | Should -Be $configData.AllNodes[0].InterfaceAlias
                    $current.AddressFamily | Should -Be $configData.AllNodes[0].AddressFamily
                    $current.IPAddress | Should -Be $configData.AllNodes[0].IPAddress
                }
            }
        }

        Context 'When a two IP addresses are specified' {
            It 'Should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName       = 'localhost'
                                InterfaceAlias = 'NetworkingDscLBA2'
                                AddressFamily  = 'IPv4'
                                IPAddress      = @('10.12.13.14/16', '10.13.14.16/32')
                            }
                        )
                    }

                    & "$($script:dscResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData

                    Start-DscConfiguration `
                        -Path $TestDrive `
                        -ComputerName localhost `
                        -Wait `
                        -Verbose `
                        -Force `
                        -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                }
                $current.InterfaceAlias | Should -Be $configData.AllNodes[0].InterfaceAlias
                $current.AddressFamily | Should -Be $configData.AllNodes[0].AddressFamily
                $current.IPAddress | Should -Contain $configData.AllNodes[0].IPAddress[0]
                $current.IPAddress | Should -Contain $configData.AllNodes[0].IPAddress[1]
            }
        }
    }
}
finally
{
    # Remove Loopback Adapter
    Remove-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA'
    Remove-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA2'

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
