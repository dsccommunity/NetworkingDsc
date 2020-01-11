$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_NetBios'

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

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

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

    Describe "$($script:DSCResourceName)_Integration" {
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
                    & "$($script:DSCResourceName)_Config" `
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
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
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
                    & "$($script:DSCResourceName)_Config" `
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
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
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
                    & "$($script:DSCResourceName)_Config" `
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
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $result.Setting | Should -Be 'Default'
            }
        }
    }
}
finally
{
    #region FOOTER
    # Restore the Net Bios setting
    $null = $netAdapterConfig | Invoke-CimMethod `
        -MethodName SetTcpipNetbios `
        -ErrorAction Stop `
        -Arguments @{
            TcpipNetbiosOptions = $currentNetBiosSetting
        }

    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
