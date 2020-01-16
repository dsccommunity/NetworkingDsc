$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_NetBios'

# Find an adapter we can test with. It needs to be enabled and have IP enabled.
$netAdapter = $null
$netAdapterConfig = $null
$netAdapterEnabled = Get-CimInstance -ClassName Win32_NetworkAdapter -Filter 'NetEnabled="True"'
if (-not $netAdapterEnabled)
{
    Write-Verbose -Message ('There are no enabled network adapters in this system. Integration tests will be skipped.') -Verbose
    return
}

foreach ($netAdapter in $netAdapterEnabled)
{
    $netAdapterConfig = $netAdapter |
        Get-CimAssociatedInstance -ResultClassName Win32_NetworkAdapterConfiguration |
        Where-Object -FilterScript { $_.IPEnabled -eq $True }
    if ($netAdapterConfig)
    {
        break
    }
}
if (-not $netAdapterConfig)
{
    Write-Verbose -Message ('There are no enabled network adapters with IP enabled in this system. Integration tests will be skipped.') -Verbose
    return
}
Write-Verbose -Message ('A network adapter ({0}) was found in this system that meets requirements for integration testing.' -f $netAdapter.NetConnectionID) -Verbose

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
    Describe 'NetBios Integration Tests' {
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile -Verbose -ErrorAction Stop

        $tcpipNetbiosOptions = $netAdapterConfig.TcpipNetbiosOptions

        # Store the current Net Bios setting
        if ($null -eq $tcpipNetbiosOptions)
        {
            $currentNetBiosSetting = [NetBiosSetting]::Default
        }
        else
        {
            $currentNetBiosSetting = [NetBiosSetting].GetEnumValues()[$tcpipNetbiosOptions]
        }

        # Ensure the Net Bios setting is in a known state (enabled)
        $null = $netAdapterConfig | Invoke-CimMethod `
            -MethodName SetTcpipNetbios `
            -ErrorAction Stop `
            -Arguments @{
                TcpipNetbiosOptions = [uint32][NetBiosSetting]::Enable
            }

        Describe "$($script:dscResourceName)_Integration" {
            Context 'Disable NetBios over TCP/IP' {
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName            = 'localhost'
                            InterfaceAlias      = $netAdapter.NetConnectionID
                            Setting             = 'Disable'
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

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should have set the resource and all setting should match current state' {
                    $result = Get-DscConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                    }
                    $result.Setting | Should -Be 'Disable'
                }
            }

            Context 'Enable NetBios over TCP/IP' {
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName            = 'localhost'
                            InterfaceAlias      = $netAdapter.NetConnectionID
                            Setting             = 'Enable'
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

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should have set the resource and all setting should match current state' {
                    $result = Get-DscConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                    }
                    $result.Setting | Should -Be 'Enable'
                }
            }

            Context 'Default NetBios over TCP/IP' {
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName            = 'localhost'
                            InterfaceAlias      = $netAdapter.NetConnectionID
                            Setting             = 'Default'
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

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should have set the resource and all setting should match current state' {
                    $result = Get-DscConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                    }
                    $result.Setting | Should -Be 'Default'
                }
            }
        }
    }
}
finally
{
    # Restore the Net Bios setting
    $null = $netAdapterConfig | Invoke-CimMethod `
        -MethodName SetTcpipNetbios `
        -ErrorAction Stop `
        -Arguments @{
            TcpipNetbiosOptions = $currentNetBiosSetting
        }

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
