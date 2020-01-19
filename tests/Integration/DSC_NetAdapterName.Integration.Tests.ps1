$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_NetAdapterName'

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
    Describe 'NetAdapterName Integration Tests' {
        Describe "$($script:dscResourceName)_Integration using all parameters" {
            $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_all.config.ps1"
            . $configFile -Verbose -ErrorAction Stop

            BeforeAll {
                New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA'
                $adapter = Get-NetAdapter -Name 'NetworkingDscLBA'
            }

            AfterAll {
                # Remove Loopback Adapter
                Remove-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA'
                Remove-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBANew'
            }

            It 'Should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName             = 'localhost'
                                NewName              = 'NetworkingDscLBANew'
                                Name                 = $adapter.Name
                                PhysicalMediaType    = $adapter.PhysicalMediaType
                                Status               = $adapter.Status
                                MacAddress           = $adapter.MacAddress
                                InterfaceDescription = $adapter.InterfaceDescription
                                InterfaceIndex       = $adapter.InterfaceIndex
                                InterfaceGuid        = $adapter.InterfaceGuid
                            }
                        )
                    }

                    & "$($script:dscResourceName)_Config_All" `
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

            It 'Should reapply the MOF without throwing' {
                {
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
                {
                    Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config_All"
                }
                $current.Name | Should -Be 'NetworkingDscLBANew'
            }
        }

        Describe "$($script:dscResourceName)_Integration using name parameter only" {
            $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_nameonly.config.ps1"
            . $configFile -Verbose -ErrorAction Stop

            BeforeAll {
                New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA'
                $adapter = Get-NetAdapter -Name 'NetworkingDscLBA'
            }

            AfterAll {
                # Remove Loopback Adapter
                Remove-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA'
                Remove-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBANew'
            }

            It 'Should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName = 'localhost'
                                NewName  = 'NetworkingDscLBANew'
                                Name     = $adapter.Name
                            }
                        )
                    }

                    & "$($script:dscResourceName)_Config_NameOnly" `
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

            It 'Should reapply the MOF without throwing' {
                {
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
                {
                    Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config_NameOnly"
                }
                $current.Name | Should -Be 'NetworkingDscLBANew'
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
