$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_WinsSetting'

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
    . $ConfigFile

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

    Describe "$($script:DSCResourceName)_Integration" {
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
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should have set the resource and all setting should match current state' {
                $result = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
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
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should have set the resource and all setting should match current state' {
                $result = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $result.EnableLmHosts | Should -Be $true
                $result.EnableDns | Should -Be $true
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

    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
