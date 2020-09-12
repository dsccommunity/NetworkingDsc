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
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile -Verbose -ErrorAction Stop

        BeforeAll {
            New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA1'
            New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA2'
        }

        AfterAll {
            Remove-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA1'
            Remove-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA2'
        }

        Describe "$($script:dscResourceName)_Integration" {
            Context 'When a single IP address is specified' {
                # This is to pass to the Config
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName       = 'localhost'
                            InterfaceAlias = 'NetworkingDscLBA1'
                            AddressFamily  = 'IPv4'
                            IPAddress      = '10.11.12.13/16'
                        }
                    )
                }

                It 'Should compile and apply the MOF without throwing' {
                    {
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
                    $current[0].InterfaceAlias | Should -Be $configData.AllNodes[0].InterfaceAlias
                    $current[0].AddressFamily | Should -Be $configData.AllNodes[0].AddressFamily
                    $current[0].IPAddress | Should -Be $configData.AllNodes[0].IPAddress
                }
            }
        }

        Context 'When a two IP addresses are specified' {
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

            It 'Should compile and apply the MOF without throwing' {
                {
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
                $current[0].InterfaceAlias | Should -Be $configData.AllNodes[0].InterfaceAlias
                $current[0].AddressFamily | Should -Be $configData.AllNodes[0].AddressFamily
                $current[0].IPAddress | Should -Contain $configData.AllNodes[0].IPAddress[0]
                $current[0].IPAddress | Should -Contain $configData.AllNodes[0].IPAddress[1]
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
