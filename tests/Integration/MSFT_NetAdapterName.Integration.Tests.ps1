$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_NetAdapterName'

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

# Configure Loopback Adapter
. (Join-Path -Path (Split-Path -Parent $Script:MyInvocation.MyCommand.Path) -ChildPath 'IntegrationHelper.ps1')

# Using try/finally to always cleanup even if something awful happens.
try
{
    #region Integration Tests with all parameters
    Describe "$($script:DSCResourceName)_Integration using all parameters" {
        $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName)_all.config.ps1"
        . $ConfigFile -Verbose -ErrorAction Stop

        BeforeAll {
            $adapterName = 'NetworkingDscLBA'
            New-IntegrationLoopbackAdapter -AdapterName $adapterName
            $adapter = Get-NetAdapter -Name $adapterName
            $newAdapterName = 'NetworkingDscLBANew'
        }

        #region DEFAULT TESTS
        It 'Should compile and apply the MOF without throwing' {
            {
                # This is to pass to the Config
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName             = 'localhost'
                            NewName              = $newAdapterName
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

                & "$($script:DSCResourceName)_Config_All" `
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
        #endregion

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq "$($script:DSCResourceName)_Config_All"
            }
            $current.Name | Should -Be $newAdapterName
        }

        AfterAll {
            # Remove Loopback Adapter
            Remove-IntegrationLoopbackAdapter -AdapterName $adapterName
            Remove-IntegrationLoopbackAdapter -AdapterName $newAdapterName
        }
    }
    #endregion

    #region Integration Tests with name parameter only
    Describe "$($script:DSCResourceName)_Integration using name parameter only" {
        $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName)_nameonly.config.ps1"
        . $ConfigFile -Verbose -ErrorAction Stop

        BeforeAll {
            $adapterName = 'NetworkingDscLBA'
            New-IntegrationLoopbackAdapter -AdapterName $adapterName
            $adapter = Get-NetAdapter -Name $adapterName
            $newAdapterName = 'NetworkingDscLBANew'
        }

        #region DEFAULT TESTS
        It 'Should compile and apply the MOF without throwing' {
            {
                # This is to pass to the Config
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName = 'localhost'
                            NewName  = $newAdapterName
                            Name     = $adapter.Name
                        }
                    )
                }

                & "$($script:DSCResourceName)_Config_NameOnly" `
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
        #endregion

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq "$($script:DSCResourceName)_Config_NameOnly"
            }
            $current.Name | Should -Be $newAdapterName
        }

        AfterAll {
            # Remove Loopback Adapter
            Remove-IntegrationLoopbackAdapter -AdapterName $adapterName
            Remove-IntegrationLoopbackAdapter -AdapterName $newAdapterName
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
