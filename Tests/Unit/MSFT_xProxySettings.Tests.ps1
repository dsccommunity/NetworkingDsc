$script:DSCModuleName = 'xNetworking'
$script:DSCResourceName = 'MSFT_xProxySettings'

#region HEADER
# Unit Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xNetworking'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $script:DSCResourceName {
        $script:DSCResourceName = 'MSFT_xProxySettings'

        # Create the Mock Objects that will be used for running tests
        $testProxyServer = 'testproxy:8888'
        $testProxyExeceptions = @('exception1.contoso.com', 'exception2.contoso.com')
        $testAutoConfigURL = 'http://wpad.contoso.com/test.wpad'

        $testProxyAllDisabledSettings = [PSObject] @{
            EnableAutoDetection     = $False
            EnableManualProxy       = $False
            EnableAutoConfiguration = $False
        }

        $testProxyManualProxySettings = [PSObject] @{
            EnableAutoDetection     = $False
            EnableManualProxy       = $True
            ProxyServer             = $testProxyServer
            EnableAutoConfiguration = $False
        }

        $testProxyManualProxyWithExceptionsSettings = [PSObject] @{
            EnableAutoDetection     = $False
            EnableManualProxy       = $True
            ProxyServer             = $testProxyServer
            ProxyServerExceptions   = $testProxyExeceptions
            EnableAutoConfiguration = $False
        }

        $testProxyManualProxyWithBypassLocalOnlySettings = [PSObject] @{
            EnableAutoDetection     = $False
            EnableManualProxy       = $True
            ProxyServer             = $testProxyServer
            ProxyServerBypassLocal  = $True
            EnableAutoConfiguration = $False
        }

        $testProxyAutoConfigOnlySettings = [PSObject] @{
            EnableAutoDetection     = $False
            EnableManualProxy       = $False
            EnableAutoConfiguration = $True
            AutoConfigURL           = $testAutoConfigURL
        }

        $testProxyAllEnabledWithoutBypassLocalSettings = [PSObject] @{
            EnableAutoDetection     = $True
            EnableManualProxy       = $True
            ProxyServer             = $testProxyServer
            ProxyServerBypassLocal  = $False
            ProxyServerExceptions   = $testProxyExeceptions
            EnableAutoConfiguration = $True
            AutoConfigURL           = $testAutoConfigURL
        }

        $testProxyAllEnabledWithBypassLocalSettings = [PSObject] @{
            EnableAutoDetection     = $True
            EnableManualProxy       = $True
            ProxyServer             = $testProxyServer
            ProxyServerBypassLocal  = $True
            ProxyServerExceptions   = $testProxyExeceptions
            EnableAutoConfiguration = $True
            AutoConfigURL           = $testAutoConfigURL
        }

        Describe "$script:DSCResourceName\Convert*-ProxySettingsBinary" {
            Context 'All Proxy Types Disabled' {
                It 'Should not throw exception when converting to Proxy Settings Binary' {
                    { $script:proxyBinary = ConvertTo-ProxySettingsBinary @testProxyAllDisabledSettings } | Should Not Throw
                }

                It 'Should not throw exception when converting from Proxy Settings Binary' {
                    { $script:proxySettingsResult = ConvertFrom-ProxySettingsBinary -ProxySettings $script:proxyBinary } | Should Not Throw
                }

                It 'Should convert the values to binary and back to source values correctly' {
                    $script:proxySettingsResult.EnableAutoDetection | Should Be $testProxyAllDisabledSettings.EnableAutoDetection
                    $script:proxySettingsResult.EnableManualProxy | Should Be $testProxyAllDisabledSettings.EnableManualProxy
                    $script:proxySettingsResult.ProxyServer | Should BeNullOrEmpty
                    $script:proxySettingsResult.ProxyServerBypassLocal | Should Be $False
                    $script:proxySettingsResult.ProxyServerExceptions | Should BeNullOrEmpty
                    $script:proxySettingsResult.EnableAutoConfiguration | Should Be $testProxyAllDisabledSettings.EnableAutoConfiguration
                    $script:proxySettingsResult.AutoConfigURL | Should BeNullOrEmpty
                }
            }

            Context 'Only Manual Proxy Server type Enabled' {
                It 'Should not throw exception when converting to Proxy Settings Binary' {
                    { $script:proxyBinary = ConvertTo-ProxySettingsBinary @testProxyManualProxySettings } | Should Not Throw
                }

                It 'Should not throw exception when converting from Proxy Settings Binary' {
                    { $script:proxySettingsResult = ConvertFrom-ProxySettingsBinary -ProxySettings $script:proxyBinary } | Should Not Throw
                }

                It 'Should convert the values to binary and back to source values correctly' {
                    $script:proxySettingsResult.EnableAutoDetection | Should Be $testProxyManualProxySettings.EnableAutoDetection
                    $script:proxySettingsResult.EnableManualProxy | Should Be $testProxyManualProxySettings.EnableManualProxy
                    $script:proxySettingsResult.ProxyServer | Should Be $testProxyManualProxySettings.ProxyServer
                    $script:proxySettingsResult.ProxyServerBypassLocal | Should Be $False
                    $script:proxySettingsResult.ProxyServerExceptions | Should BeNullOrEmpty
                    $script:proxySettingsResult.EnableAutoConfiguration | Should Be $testProxyManualProxySettings.EnableAutoConfiguration
                    $script:proxySettingsResult.AutoConfigURL | Should BeNullOrEmpty
                }
            }

            Context 'Only Manual Proxy Server type Enabled with Exceptions Only' {
                It 'Should not throw exception when converting to Proxy Settings Binary' {
                    { $script:proxyBinary = ConvertTo-ProxySettingsBinary @testProxyManualProxyWithExceptionsSettings } | Should Not Throw
                }

                It 'Should not throw exception when converting from Proxy Settings Binary' {
                    { $script:proxySettingsResult = ConvertFrom-ProxySettingsBinary -ProxySettings $script:proxyBinary } | Should Not Throw
                }

                It 'Should convert the values to binary and back to source values correctly' {
                    $script:proxySettingsResult.EnableAutoDetection | Should Be $testProxyManualProxyWithExceptionsSettings.EnableAutoDetection
                    $script:proxySettingsResult.EnableManualProxy | Should Be $testProxyManualProxyWithExceptionsSettings.EnableManualProxy
                    $script:proxySettingsResult.ProxyServer | Should Be $testProxyManualProxyWithExceptionsSettings.ProxyServer
                    $script:proxySettingsResult.ProxyServerBypassLocal | Should Be $False
                    $script:proxySettingsResult.ProxyServerExceptions | Should Be $testProxyManualProxyWithExceptionsSettings.ProxyServerExceptions
                    $script:proxySettingsResult.EnableAutoConfiguration | Should Be $testProxyManualProxyWithExceptionsSettings.EnableAutoConfiguration
                    $script:proxySettingsResult.AutoConfigURL | Should BeNullOrEmpty
                }
            }

            Context 'Only Manual Proxy Server type Enabled with Bypass Local Only' {
                It 'Should not throw exception when converting to Proxy Settings Binary' {
                    { $script:proxyBinary = ConvertTo-ProxySettingsBinary @testProxyManualProxyWithBypassLocalOnlySettings } | Should Not Throw
                }

                It 'Should not throw exception when converting from Proxy Settings Binary' {
                    { $script:proxySettingsResult = ConvertFrom-ProxySettingsBinary -ProxySettings $script:proxyBinary } | Should Not Throw
                }

                It 'Should convert the values to binary and back to source values correctly' {
                    $script:proxySettingsResult.EnableAutoDetection | Should Be $testProxyManualProxyWithBypassLocalOnlySettings.EnableAutoDetection
                    $script:proxySettingsResult.EnableManualProxy | Should Be $testProxyManualProxyWithBypassLocalOnlySettings.EnableManualProxy
                    $script:proxySettingsResult.ProxyServer | Should Be $testProxyManualProxyWithBypassLocalOnlySettings.ProxyServer
                    $script:proxySettingsResult.ProxyServerBypassLocal | Should Be $True
                    $script:proxySettingsResult.ProxyServerExceptions | Should BeNullOrEmpty
                    $script:proxySettingsResult.EnableAutoConfiguration | Should Be $testProxyManualProxyWithBypassLocalOnlySettings.EnableAutoConfiguration
                    $script:proxySettingsResult.AutoConfigURL | Should BeNullOrEmpty
                }
            }

            Context 'Only Auto Config Proxy type Enabled' {
                It 'Should not throw exception when converting to Proxy Settings Binary' {
                    { $script:proxyBinary = ConvertTo-ProxySettingsBinary @testProxyAutoConfigOnlySettings } | Should Not Throw
                }

                It 'Should not throw exception when converting from Proxy Settings Binary' {
                    { $script:proxySettingsResult = ConvertFrom-ProxySettingsBinary -ProxySettings $script:proxyBinary } | Should Not Throw
                }

                It 'Should convert the values to binary and back to source values correctly' {
                    $script:proxySettingsResult.EnableAutoDetection | Should Be $testProxyAutoConfigOnlySettings.EnableAutoDetection
                    $script:proxySettingsResult.EnableManualProxy | Should Be $testProxyAutoConfigOnlySettings.EnableManualProxy
                    $script:proxySettingsResult.ProxyServer | Should BeNullOrEmpty
                    $script:proxySettingsResult.ProxyServerBypassLocal | Should Be $False
                    $script:proxySettingsResult.ProxyServerExceptions | Should BeNullOrEmpty
                    $script:proxySettingsResult.EnableAutoConfiguration | Should Be $testProxyAutoConfigOnlySettings.EnableAutoConfiguration
                    $script:proxySettingsResult.AutoConfigURL | Should Be $testProxyAutoConfigOnlySettings.AutoConfigURL
                }
            }

            Context 'All Proxy Types Enabled and Proxy Bypass Local Disabled' {
                It 'Should not throw exception when converting to Proxy Settings Binary' {
                    { $script:proxyBinary = ConvertTo-ProxySettingsBinary @testProxyAllEnabledWithoutBypassLocalSettings } | Should Not Throw
                }

                It 'Should not throw exception when converting from Proxy Settings Binary' {
                    { $script:proxySettingsResult = ConvertFrom-ProxySettingsBinary -ProxySettings $script:proxyBinary } | Should Not Throw
                }

                It 'Should convert the values to binary and back to source values correctly' {
                    $script:proxySettingsResult.EnableAutoDetection | Should Be $testProxyAllEnabledWithoutBypassLocalSettings.EnableAutoDetection
                    $script:proxySettingsResult.EnableManualProxy | Should Be $testProxyAllEnabledWithoutBypassLocalSettings.EnableManualProxy
                    $script:proxySettingsResult.ProxyServer | Should Be $testProxyAllEnabledWithoutBypassLocalSettings.ProxyServer
                    $script:proxySettingsResult.ProxyServerBypassLocal | Should Be $testProxyAllEnabledWithoutBypassLocalSettings.ProxyServerBypassLocal
                    $script:proxySettingsResult.ProxyServerExceptions | Should Be $testProxyAllEnabledWithoutBypassLocalSettings.ProxyServerExceptions
                    $script:proxySettingsResult.EnableAutoConfiguration | Should Be $testProxyAllEnabledWithoutBypassLocalSettings.EnableAutoConfiguration
                    $script:proxySettingsResult.AutoConfigURL | Should Be $testProxyAllEnabledWithoutBypassLocalSettings.AutoConfigURL
                }
            }

            Context 'All Proxy Types Enabled and Proxy Bypass Local Enabled' {
                It 'Should not throw exception when converting to Proxy Settings Binary' {
                    { $script:proxyBinary = ConvertTo-ProxySettingsBinary @testProxyAllEnabledWithBypassLocalSettings } | Should Not Throw
                }

                It 'Should not throw exception when converting from Proxy Settings Binary' {
                    { $script:proxySettingsResult = ConvertFrom-ProxySettingsBinary -ProxySettings $script:proxyBinary } | Should Not Throw
                }

                It 'Should convert the values to binary and back to source values correctly' {
                    $script:proxySettingsResult.EnableAutoDetection | Should Be $testProxyAllEnabledWithBypassLocalSettings.EnableAutoDetection
                    $script:proxySettingsResult.EnableManualProxy | Should Be $testProxyAllEnabledWithBypassLocalSettings.EnableManualProxy
                    $script:proxySettingsResult.ProxyServer | Should Be $testProxyAllEnabledWithBypassLocalSettings.ProxyServer
                    $script:proxySettingsResult.ProxyServerBypassLocal | Should Be $testProxyAllEnabledWithBypassLocalSettings.ProxyServerBypassLocal
                    $script:proxySettingsResult.ProxyServerExceptions | Should Be $testProxyAllEnabledWithBypassLocalSettings.ProxyServerExceptions
                    $script:proxySettingsResult.EnableAutoConfiguration | Should Be $testProxyAllEnabledWithBypassLocalSettings.EnableAutoConfiguration
                    $script:proxySettingsResult.AutoConfigURL | Should Be $testProxyAllEnabledWithBypassLocalSettings.AutoConfigURL
                }
            }
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
