$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_NetIPInterface'

#region HEADER
# Integration Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\NetworkingDsc'

if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration
#endregion

# Configure Loopback Adapter and disable all settings
. (Join-Path -Path (Split-Path -Parent $Script:MyInvocation.MyCommand.Path) -ChildPath 'IntegrationHelper.ps1')
New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA'

<#
    The following settings are not supported by the loopback adapter so
    can not be tested using these tests:
    - Advertising
    - Automatic Metric (can not be disabled after being enabled)
#>
$setNetIPInterfaceParameters = @{
    InterfaceAlias        = 'NetworkingDscLBA'
    AddressFamily         = 'IPv4'
    AdvertiseDefaultRoute = 'Disabled'
    AutomaticMetric       = 'Disabled'
    DirectedMacWolPattern = 'Disabled'
    EcnMarking            = 'Disabled'
    Forwarding            = 'Disabled'
    IgnoreDefaultRoutes   = 'Disabled'
}
Set-NetIPInterface @setNetIPInterfaceParameters

# Using try/finally to always cleanup even if something awful happens.
try
{
    #region Integration Tests
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    Describe "$($script:DSCResourceName)_Integration" {
        Context 'When all settings are enabled' {
            # This is to pass to the Config
            $script:configData = @{
                AllNodes = @(
                    @{
                        NodeName              = 'localhost'
                        InterfaceAlias        = 'NetworkingDscLBA'
                        AddressFamily         = 'IPv4'
                        AdvertiseDefaultRoute = 'Enabled'
                        AutomaticMetric       = 'Enabled'
                        DirectedMacWolPattern = 'Enabled'
                        EcnMarking            = 'AppDecide'
                        Forwarding            = 'Enabled'
                        IgnoreDefaultRoutes   = 'Enabled'
                    }
                )
            }

            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:DSCResourceName)_Config_Enabled" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $script:configData

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

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config_Enabled"
                }
                $current.InterfaceAlias        | Should -Be $script:configData.AllNodes[0].InterfaceAlias
                $current.AddressFamily         | Should -Be $script:configData.AllNodes[0].AddressFamily
                $current.AdvertiseDefaultRoute | Should -Be $script:configData.AllNodes[0].AdvertiseDefaultRoute
                $current.AutomaticMetric       | Should -Be $script:configData.AllNodes[0].AutomaticMetric
                $current.DirectedMacWolPattern | Should -Be $script:configData.AllNodes[0].DirectedMacWolPattern
                $current.EcnMarking            | Should -Be $script:configData.AllNodes[0].EcnMarking
                $current.Forwarding            | Should -Be $script:configData.AllNodes[0].Forwarding
                $current.IgnoreDefaultRoutes   | Should -Be $script:configData.AllNodes[0].IgnoreDefaultRoutes
            }
        }

        Context 'When all settings are disabled' {
            # This is to pass to the Config
            $script:configData = @{
                AllNodes = @(
                    @{
                        NodeName              = 'localhost'
                        InterfaceAlias        = 'NetworkingDscLBA'
                        AddressFamily         = 'IPv4'
                        AdvertiseDefaultRoute = 'Disabled'
                        DirectedMacWolPattern = 'Disabled'
                        EcnMarking            = 'Disabled'
                        Forwarding            = 'Disabled'
                        IgnoreDefaultRoutes   = 'Disabled'
                    }
                )
            }

            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:DSCResourceName)_Config_Disabled" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $script:configData

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

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config_Disabled"
                }
                $current.InterfaceAlias        | Should -Be $script:configData.AllNodes[0].InterfaceAlias
                $current.AddressFamily         | Should -Be $script:configData.AllNodes[0].AddressFamily
                $current.AdvertiseDefaultRoute | Should -Be $script:configData.AllNodes[0].AdvertiseDefaultRoute
                $current.DirectedMacWolPattern | Should -Be $script:configData.AllNodes[0].DirectedMacWolPattern
                $current.EcnMarking            | Should -Be $script:configData.AllNodes[0].EcnMarking
                $current.Forwarding            | Should -Be $script:configData.AllNodes[0].Forwarding
                $current.IgnoreDefaultRoutes   | Should -Be $script:configData.AllNodes[0].IgnoreDefaultRoutes
            }
        }
    }
}
finally
{
    # Remove Loopback Adapter
    Remove-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA'

    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
