$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_WinsServerAddress'

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
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -TestType Integration
#endregion

# Load the Integration Helper
. (Join-Path -Path (Split-Path -Parent $Script:MyInvocation.MyCommand.Path) -ChildPath 'IntegrationHelper.ps1')

# Configure Loopback Adapter
$adapterName = 'NetworkingDsc'
New-IntegrationLoopbackAdapter -AdapterName $adapterName

# Using try/finally to always cleanup even if something awful happens.
try
{
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
                            InterfaceAlias = $adapterName
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
            $current = Get-DscConfiguration | Where-Object { $_.ConfigurationName -eq "$($script:dscResourceName)_Config_Configured" }
            $current.InterfaceAlias | Should -Be $adapterName
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
                            InterfaceAlias = $adapterName
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
            $current = Get-DscConfiguration | Where-Object { $_.ConfigurationName -eq "$($script:dscResourceName)_Config_Configured" }
            $current.InterfaceAlias | Should -Be $adapterName
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
                            InterfaceAlias = $adapterName
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
            $current = Get-DscConfiguration | Where-Object { $_.ConfigurationName -eq "$($script:dscResourceName)_Config_Configured" }
            $current.InterfaceAlias | Should -Be $adapterName
            $current.Address | Should -BeNullOrEmpty
        }
    }
}
finally
{
    # Remove Loopback Adapter
    Remove-IntegrationLoopbackAdapter -AdapterName $adapterName

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
