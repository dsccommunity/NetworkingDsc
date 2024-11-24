[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }

    <#
        Need to define that variables here to be used in the Pester Discover to
        build the ForEach-blocks.
    #>
    $script:dscResourceFriendlyName = 'WinsSetting'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'NetworkingDsc'
    $script:dscResourceFriendlyName = 'WinsSetting'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

AfterAll {
    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Describe 'WinsSetting Integration Tests' {
    Describe "$($script:dscResourceName)_Integration" {
        BeforeAll {
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
        }

        AfterAll {
            # Restore the WINS settings
            $null = Invoke-CimMethod `
                -ClassName Win32_NetworkAdapterConfiguration `
                -MethodName EnableWins `
                -Arguments @{
                DNSEnabledForWINSResolution = $currentEnableDns
                WINSEnableLMHostsLookup     = $currentEnableLmHosts
            }
        }

        Context 'Disable all settings' {
            BeforeAll {
                $configurationData = @{
                    AllNodes = @(
                        @{
                            NodeName      = 'localhost'
                            EnableLmHosts = $false
                            EnableDns     = $false
                        }
                    )
                }
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
            BeforeAll {
                $configurationData = @{
                    AllNodes = @(
                        @{
                            NodeName      = 'localhost'
                            EnableLmHosts = $true
                            EnableDns     = $true
                        }
                    )
                }
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
