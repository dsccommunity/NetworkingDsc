$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_NetIPInterface'

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
    Describe 'NetIPInterface Integration Tests' {
        New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA'

        <#
            The following settings are not supported by the loopback adapter so
            can not be tested using these tests:
            - Advertising
            - AutomaticMetric (can not be disabled after being enabled)
            - NeighborUnreachabilityDetection

            Applying the above configuration settings to the loopback adapter
            results in a "The parameter is incorrect" error message.
        #>
        $setNetIPInterfaceParameters = @{
            InterfaceAlias              = 'NetworkingDscLBA'
            AddressFamily               = 'IPv4'
            AdvertiseDefaultRoute       = 'Disabled'
            AutomaticMetric             = 'Disabled'
            Dhcp                        = 'Disabled'
            DirectedMacWolPattern       = 'Disabled'
            EcnMarking                  = 'Disabled'
            ForceArpNdWolPattern        = 'Disabled'
            Forwarding                  = 'Disabled'
            IgnoreDefaultRoutes         = 'Disabled'
            ManagedAddressConfiguration = 'Disabled'
            OtherStatefulConfiguration  = 'Disabled'
            RouterDiscovery             = 'Disabled'
            WeakHostReceive             = 'Disabled'
            WeakHostSend                = 'Disabled'
        }
        Set-NetIPInterface @setNetIPInterfaceParameters

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile -Verbose -ErrorAction Stop

        Describe "$($script:dscResourceName)_Integration" {
            Context 'When all settings are enabled' {
                # This is to pass to the Config
                $script:configData = @{
                    AllNodes = @(
                        @{
                            NodeName                        = 'localhost'
                            InterfaceAlias                  = 'NetworkingDscLBA'
                            AddressFamily                   = 'IPv4'
                            AdvertiseDefaultRoute           = 'Enabled'
                            AutomaticMetric                 = 'Enabled'
                            Dhcp                            = 'Enabled'
                            DirectedMacWolPattern           = 'Enabled'
                            EcnMarking                      = 'AppDecide'
                            ForceArpNdWolPattern            = 'Enabled'
                            Forwarding                      = 'Enabled'
                            IgnoreDefaultRoutes             = 'Enabled'
                            ManagedAddressConfiguration     = 'Enabled'
                            NeighborUnreachabilityDetection = 'Enabled'
                            OtherStatefulConfiguration      = 'Enabled'
                            RouterDiscovery                 = 'ControlledByDHCP'
                            WeakHostReceive                 = 'Enabled'
                            WeakHostSend                    = 'Enabled'
                            NlMtu                           = 1600
                        }
                    )
                }

                It 'Should compile and apply the MOF without throwing' {
                    {
                        & "$($script:dscResourceName)_Config_Enabled" `
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
                        $_.ConfigurationName -eq "$($script:dscResourceName)_Config_Enabled"
                    }
                    $current.InterfaceAlias                  | Should -Be $script:configData.AllNodes[0].InterfaceAlias
                    $current.AddressFamily                   | Should -Be $script:configData.AllNodes[0].AddressFamily
                    $current.AdvertiseDefaultRoute           | Should -Be $script:configData.AllNodes[0].AdvertiseDefaultRoute
                    $current.AutomaticMetric                 | Should -Be $script:configData.AllNodes[0].AutomaticMetric
                    $current.Dhcp                            | Should -Be $script:configData.AllNodes[0].Dhcp
                    $current.DirectedMacWolPattern           | Should -Be $script:configData.AllNodes[0].DirectedMacWolPattern
                    $current.EcnMarking                      | Should -Be $script:configData.AllNodes[0].EcnMarking
                    $current.ForceArpNdWolPattern            | Should -Be $script:configData.AllNodes[0].ForceArpNdWolPattern
                    $current.Forwarding                      | Should -Be $script:configData.AllNodes[0].Forwarding
                    $current.IgnoreDefaultRoutes             | Should -Be $script:configData.AllNodes[0].IgnoreDefaultRoutes
                    $current.ManagedAddressConfiguration     | Should -Be $script:configData.AllNodes[0].ManagedAddressConfiguration
                    $current.NeighborUnreachabilityDetection | Should -Be $script:configData.AllNodes[0].NeighborUnreachabilityDetection
                    $current.OtherStatefulConfiguration      | Should -Be $script:configData.AllNodes[0].OtherStatefulConfiguration
                    $current.RouterDiscovery                 | Should -Be $script:configData.AllNodes[0].RouterDiscovery
                    $current.WeakHostReceive                 | Should -Be $script:configData.AllNodes[0].WeakHostReceive
                    $current.WeakHostSend                    | Should -Be $script:configData.AllNodes[0].WeakHostSend
                }
            }

            Context 'When all settings are disabled' {
                # This is to pass to the Config
                $script:configData = @{
                    AllNodes = @(
                        @{
                            NodeName                    = 'localhost'
                            InterfaceAlias              = 'NetworkingDscLBA'
                            AddressFamily               = 'IPv4'
                            AdvertiseDefaultRoute       = 'Disabled'
                            AutomaticMetric             = 'Disabled'
                            Dhcp                        = 'Disabled'
                            DirectedMacWolPattern       = 'Disabled'
                            EcnMarking                  = 'Disabled'
                            Forwarding                  = 'Disabled'
                            ForceArpNdWolPattern        = 'Disabled'
                            IgnoreDefaultRoutes         = 'Disabled'
                            ManagedAddressConfiguration = 'Disabled'
                            OtherStatefulConfiguration  = 'Disabled'
                            RouterDiscovery             = 'Disabled'
                            WeakHostReceive             = 'Disabled'
                            WeakHostSend                = 'Disabled'
                            NlMtu                       = 1500
                            InterfaceMetric             = 20
                        }
                    )
                }

                It 'Should compile and apply the MOF without throwing' {
                    {
                        & "$($script:dscResourceName)_Config_Disabled" `
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
                        $_.ConfigurationName -eq "$($script:dscResourceName)_Config_Disabled"
                    }
                    $current.InterfaceAlias                  | Should -Be $script:configData.AllNodes[0].InterfaceAlias
                    $current.AddressFamily                   | Should -Be $script:configData.AllNodes[0].AddressFamily
                    $current.AdvertiseDefaultRoute           | Should -Be $script:configData.AllNodes[0].AdvertiseDefaultRoute
                    $current.AutomaticMetric                 | Should -Be $script:configData.AllNodes[0].AutomaticMetric
                    $current.Dhcp                            | Should -Be $script:configData.AllNodes[0].Dhcp
                    $current.DirectedMacWolPattern           | Should -Be $script:configData.AllNodes[0].DirectedMacWolPattern
                    $current.EcnMarking                      | Should -Be $script:configData.AllNodes[0].EcnMarking
                    $current.ForceArpNdWolPattern            | Should -Be $script:configData.AllNodes[0].ForceArpNdWolPattern
                    $current.Forwarding                      | Should -Be $script:configData.AllNodes[0].Forwarding
                    $current.IgnoreDefaultRoutes             | Should -Be $script:configData.AllNodes[0].IgnoreDefaultRoutes
                    $current.ManagedAddressConfiguration     | Should -Be $script:configData.AllNodes[0].ManagedAddressConfiguration
                    $current.OtherStatefulConfiguration      | Should -Be $script:configData.AllNodes[0].OtherStatefulConfiguration
                    $current.RouterDiscovery                 | Should -Be $script:configData.AllNodes[0].RouterDiscovery
                    $current.WeakHostReceive                 | Should -Be $script:configData.AllNodes[0].WeakHostReceive
                    $current.WeakHostSend                    | Should -Be $script:configData.AllNodes[0].WeakHostSend
                    $current.NlMtu                           | Should -Be $script:configData.AllNodes[0].NlMtu
                    $current.InterfaceMetric                 | Should -Be $script:configData.AllNodes[0].InterfaceMetric
                }
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
