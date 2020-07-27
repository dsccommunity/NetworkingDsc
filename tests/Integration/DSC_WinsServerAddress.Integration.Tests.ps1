$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_WinsServerAddress'

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
    Describe 'WinsServerAddress Integration Tests' {
        New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA'

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_Configured.config.ps1"
        . $configFile -Verbose -ErrorAction Stop

        Describe "$($script:dscResourceName)_Integration using single address" {
            It 'Should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName       = 'localhost'
                                InterfaceAlias = 'NetworkingDscLBA'
                                Address        = '10.139.17.99'
                            }
                        )
                    }

                    & "$($script:dscResourceName)_Config_Configured" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
                    Start-DscConfiguration -Path $TestDrive `
                        -ComputerName localhost -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config_Configured"
                }
                $current.InterfaceAlias | Should -Be 'NetworkingDscLBA'
                $current.Address.Count | Should -Be 1
                $current.Address | Should -Be '10.139.17.99'
            }
        }

        Describe "$($script:dscResourceName)_Integration using two addresses" {
            It 'Should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName       = 'localhost'
                                InterfaceAlias = 'NetworkingDscLBA'
                                Address        = '10.139.17.99', '10.139.17.100'
                            }
                        )
                    }

                    & "$($script:dscResourceName)_Config_Configured" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
                    Start-DscConfiguration -Path $TestDrive `
                        -ComputerName localhost -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config_Configured"
                }
                $current.InterfaceAlias | Should -Be 'NetworkingDscLBA'
                $current.Address.Count | Should -Be 2
                $current.Address[0] | Should -Be '10.139.17.99'
                $current.Address[1] | Should -Be '10.139.17.100'
            }
        }

        Describe "$($script:dscResourceName)_Integration using no addresses" {
            It 'Should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName       = 'localhost'
                                InterfaceAlias = 'NetworkingDscLBA'
                                Address        = @()
                            }
                        )
                    }

                    & "$($script:dscResourceName)_Config_Configured" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
                    Start-DscConfiguration -Path $TestDrive `
                        -ComputerName localhost -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config_Configured"
                }
                $current.InterfaceAlias | Should -Be 'NetworkingDscLBA'
                $current.Address | Should -BeNullOrEmpty
            }
        }
    }
}
finally
{
    # Remove Loopback Adapter
    Remove-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA'

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
