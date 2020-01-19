$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_WinsSetting'

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

Write-Verbose -Message ('A network adapter ({0}) was found in this system that meets requirements for integration testing.' -f $netAdapter.Name) -Verbose

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
    Describe 'WinsSetting Integration Tests' {
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile

        # Store the current WINS settings
        $enableDnsRegistryKey = Get-ItemProperty `
            -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' `
            -Name EnableDNS `
            -ErrorAction SilentlyContinue

        if ($enableDnsRegistryKey)
        {
            $currentEnableDNS = ($enableDnsRegistryKey.EnableDNS -eq 1)
        }
        else
        {
            # if the key does not exist, then set the default which is enabled.
            $currentEnableDNS = $true
        }

        $enableLMHostsRegistryKey = Get-ItemProperty `
            -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' `
            -Name EnableLMHOSTS `
            -ErrorAction SilentlyContinue

        $currentEnableLmHosts = ($enableLMHOSTSRegistryKey.EnableLMHOSTS -eq 1)

        # Set the WINS settings to known values
        $null = Invoke-CimMethod `
            -ClassName Win32_NetworkAdapterConfiguration `
            -MethodName EnableWins `
            -Arguments @{
                DNSEnabledForWINSResolution = $true
                WINSEnableLMHostsLookup     = $true
            }

        Describe "$($script:dscResourceName)_Integration" {
            Context 'Disable all settings' {
                $configurationData = @{
                    AllNodes = @(
                        @{
                            NodeName      = 'localhost'
                            EnableLmHosts = $false
                            EnableDns     = $false
                        }
                    )
                }

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

                It 'Should have set the resource and all setting should match current state' {
                    $result = Get-DscConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                    }
                    $result.EnableLmHosts | Should -Be $false
                    $result.EnableDns | Should -Be $false
                }
            }

            Context 'Enable all settings' {
                $configurationData = @{
                    AllNodes = @(
                        @{
                            NodeName      = 'localhost'
                            EnableLmHosts = $true
                            EnableDns     = $true
                        }
                    )
                }

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

                It 'Should have set the resource and all setting should match current state' {
                    $result = Get-DscConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                    }
                    $result.EnableLmHosts | Should -Be $true
                    $result.EnableDns | Should -Be $true
                }
            }
        }
    }
}
finally
{
    # Restore the WINS settings
    $null = Invoke-CimMethod `
        -ClassName Win32_NetworkAdapterConfiguration `
        -MethodName EnableWins `
        -Arguments @{
            DNSEnabledForWINSResolution = $currentEnableDns
            WINSEnableLMHostsLookup     = $currentEnableLmHosts
        }

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
