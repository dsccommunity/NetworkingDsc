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
        $testProxyAlternateExeceptions = @('exception1.contoso.com')
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

        $testProxyManualProxyWithAlternateExceptionsSettings = [PSObject] @{
            EnableAutoDetection     = $False
            EnableManualProxy       = $True
            ProxyServer             = $testProxyServer
            ProxyServerExceptions   = $testProxyAlternateExeceptions
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

        Describe "$script:DSCResourceName\Get-TargetResource" {
            Context 'The No Proxy Settings are Defined' {
                Mock `
                    -CommandName Get-ItemProperty `
                    -Verifiable

                It 'Should not throw exception' {
                    { $script:getTargetResourceResult = Get-TargetResource -IsSingleInstance 'Yes' -Verbose } | Should Not Throw
                }

                It 'Should return the expected values' {
                    $script:getTargetResourceResult.Ensure | Should Be 'Absent'
                }

                It 'Should call expected mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'The DefaultConnectionSettings Proxy Settings are Defined' {
                Mock `
                    -CommandName Get-ItemProperty `
                    -MockWith {
                        @{ DefaultConnectionSettings = [System.Byte[]] (0x46) }
                    } `
                    -Verifiable
                Mock `
                    -CommandName ConvertFrom-ProxySettingsBinary `
                    -MockWith {
                        return $testProxyAllEnabledWithBypassLocalSettings
                    } `
                    -Verifiable

                It 'Should not throw exception' {
                    { $script:getTargetResourceResult = Get-TargetResource -IsSingleInstance 'Yes' -Verbose } | Should Not Throw
                }

                It 'Should return the expected values' {
                    $script:getTargetResourceResult.Ensure | Should Be 'Present'
                    $script:getTargetResourceResult.EnableAutoDetection | Should Be $testProxyAllEnabledWithBypassLocalSettings.EnableAutoDetection
                    $script:getTargetResourceResult.EnableManualProxy | Should Be $testProxyAllEnabledWithBypassLocalSettings.EnableManualProxy
                    $script:getTargetResourceResult.ProxyServer | Should Be $testProxyAllEnabledWithBypassLocalSettings.ProxyServer
                    $script:getTargetResourceResult.ProxyServerBypassLocal | Should Be $testProxyAllEnabledWithBypassLocalSettings.ProxyServerBypassLocal
                    $script:getTargetResourceResult.ProxyServerExceptions | Should Be $testProxyAllEnabledWithBypassLocalSettings.ProxyServerExceptions
                    $script:getTargetResourceResult.EnableAutoConfiguration | Should Be $testProxyAllEnabledWithBypassLocalSettings.EnableAutoConfiguration
                    $script:getTargetResourceResult.AutoConfigURL | Should Be $testProxyAllEnabledWithBypassLocalSettings.AutoConfigURL
                }

                It 'Should call expected mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'The SavedLegacySettings Proxy Settings are Defined' {
                Mock `
                    -CommandName Get-ItemProperty `
                    -MockWith {
                        @{ SavedLegacySettings = [System.Byte[]] (0x46) }
                    } `
                    -Verifiable
                Mock `
                    -CommandName ConvertFrom-ProxySettingsBinary `
                    -MockWith {
                        return $testProxyAllEnabledWithBypassLocalSettings
                    } `
                    -Verifiable

                It 'Should not throw exception' {
                    { $script:getTargetResourceResult = Get-TargetResource -IsSingleInstance 'Yes' -Verbose } | Should Not Throw
                }

                It 'Should return the expected values' {
                    $script:getTargetResourceResult.Ensure | Should Be 'Present'
                    $script:getTargetResourceResult.EnableAutoDetection | Should Be $testProxyAllEnabledWithBypassLocalSettings.EnableAutoDetection
                    $script:getTargetResourceResult.EnableManualProxy | Should Be $testProxyAllEnabledWithBypassLocalSettings.EnableManualProxy
                    $script:getTargetResourceResult.ProxyServer | Should Be $testProxyAllEnabledWithBypassLocalSettings.ProxyServer
                    $script:getTargetResourceResult.ProxyServerBypassLocal | Should Be $testProxyAllEnabledWithBypassLocalSettings.ProxyServerBypassLocal
                    $script:getTargetResourceResult.ProxyServerExceptions | Should Be $testProxyAllEnabledWithBypassLocalSettings.ProxyServerExceptions
                    $script:getTargetResourceResult.EnableAutoConfiguration | Should Be $testProxyAllEnabledWithBypassLocalSettings.EnableAutoConfiguration
                    $script:getTargetResourceResult.AutoConfigURL | Should Be $testProxyAllEnabledWithBypassLocalSettings.AutoConfigURL
                }

                It 'Should call expected mocks' {
                    Assert-VerifiableMock
                }
            }
        }

        Describe "$script:DSCResourceName\Test-ProxySettings" {
            Context 'All Proxy Types Disabled' {
                It 'Should not throw exception' {
                    { $script:testProxySettingsResult = Test-ProxySettings `
                            -CurrentValues $testProxyAllDisabledSettings `
                            -DesiredValues $testProxyAllDisabledSettings `
                            -Verbose } | Should Not Throw
                }

                It 'Should return true' {
                    $script:testProxySettingsResult | Should Be $true
                }
            }

            Context 'All Proxy Types Enabled and Proxy Bypass Local Disabled with all Values Matching' {
                It 'Should not throw exception' {
                    { $script:testProxySettingsResult = Test-ProxySettings `
                            -CurrentValues $testProxyAllEnabledWithoutBypassLocalSettings `
                            -DesiredValues $testProxyAllEnabledWithoutBypassLocalSettings `
                            -Verbose  } | Should Not Throw
                }

                It 'Should return true' {
                    $script:testProxySettingsResult | Should Be $true
                }
            }

            Context 'All Proxy Types Enabled and Proxy Bypass Local Enabled with all Values Matching' {
                It 'Should not throw exception' {
                    { $script:testProxySettingsResult = Test-ProxySettings `
                            -CurrentValues $testProxyAllEnabledWithBypassLocalSettings `
                            -DesiredValues $testProxyAllEnabledWithBypassLocalSettings `
                            -Verbose  } | Should Not Throw
                }

                It 'Should return true' {
                    $script:testProxySettingsResult | Should Be $true
                }
            }

            Context 'All Proxy Types Enabled and Proxy Bypass Local Enabled with Bypass Local Not Matching' {
                It 'Should not throw exception' {
                    { $script:testProxySettingsResult = Test-ProxySettings `
                            -CurrentValues $testProxyAllEnabledWithBypassLocalSettings `
                            -DesiredValues $testProxyAllEnabledWithoutBypassLocalSettings `
                            -Verbose  } | Should Not Throw
                }

                It 'Should return false' {
                    $script:testProxySettingsResult | Should Be $false
                }
            }

            Context 'Only Manual Proxy Server type Enabled with Exceptions Only that Match' {
                It 'Should not throw exception' {
                    { $script:testProxySettingsResult = Test-ProxySettings `
                            -CurrentValues $testProxyManualProxyWithExceptionsSettings `
                            -DesiredValues $testProxyManualProxyWithExceptionsSettings `
                            -Verbose  } | Should Not Throw
                }

                It 'Should return true' {
                    $script:testProxySettingsResult | Should Be $true
                }
            }

            Context 'Only Manual Proxy Server type Enabled with Exceptions Only that do not Match' {
                It 'Should not throw exception' {
                    { $script:testProxySettingsResult = Test-ProxySettings `
                            -CurrentValues $testProxyManualProxyWithExceptionsSettings `
                            -DesiredValues $testProxyManualProxyWithAlternateExceptionsSettings `
                            -Verbose  } | Should Not Throw
                }

                It 'Should return false' {
                    $script:testProxySettingsResult | Should Be $false
                }
            }
        }

        Describe "$script:DSCResourceName\Convert*-ProxySettingsBinary" {
            Context 'All Proxy Types Disabled' {
                It 'Should not throw exception when converting to Proxy Settings Binary' {
                    { $script:proxyBinary = ConvertTo-ProxySettingsBinary @testProxyAllDisabledSettings -Verbose } | Should Not Throw
                }

                It 'Should not throw exception when converting from Proxy Settings Binary' {
                    { $script:proxySettingsResult = ConvertFrom-ProxySettingsBinary -ProxySettings $script:proxyBinary -Verbose } | Should Not Throw
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
                    { $script:proxyBinary = ConvertTo-ProxySettingsBinary @testProxyManualProxySettings -Verbose } | Should Not Throw
                }

                It 'Should not throw exception when converting from Proxy Settings Binary' {
                    { $script:proxySettingsResult = ConvertFrom-ProxySettingsBinary -ProxySettings $script:proxyBinary -Verbose } | Should Not Throw
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
                    { $script:proxyBinary = ConvertTo-ProxySettingsBinary @testProxyManualProxyWithExceptionsSettings -Verbose } | Should Not Throw
                }

                It 'Should not throw exception when converting from Proxy Settings Binary' {
                    { $script:proxySettingsResult = ConvertFrom-ProxySettingsBinary -ProxySettings $script:proxyBinary -Verbose } | Should Not Throw
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
                    { $script:proxyBinary = ConvertTo-ProxySettingsBinary @testProxyManualProxyWithBypassLocalOnlySettings -Verbose } | Should Not Throw
                }

                It 'Should not throw exception when converting from Proxy Settings Binary' {
                    { $script:proxySettingsResult = ConvertFrom-ProxySettingsBinary -ProxySettings $script:proxyBinary -Verbose } | Should Not Throw
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
                    { $script:proxyBinary = ConvertTo-ProxySettingsBinary @testProxyAutoConfigOnlySettings -Verbose } | Should Not Throw
                }

                It 'Should not throw exception when converting from Proxy Settings Binary' {
                    { $script:proxySettingsResult = ConvertFrom-ProxySettingsBinary -ProxySettings $script:proxyBinary -Verbose } | Should Not Throw
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
                    { $script:proxyBinary = ConvertTo-ProxySettingsBinary @testProxyAllEnabledWithoutBypassLocalSettings -Verbose } | Should Not Throw
                }

                It 'Should not throw exception when converting from Proxy Settings Binary' {
                    { $script:proxySettingsResult = ConvertFrom-ProxySettingsBinary -ProxySettings $script:proxyBinary -Verbose } | Should Not Throw
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
                    { $script:proxyBinary = ConvertTo-ProxySettingsBinary @testProxyAllEnabledWithBypassLocalSettings -Verbose } | Should Not Throw
                }

                It 'Should not throw exception when converting from Proxy Settings Binary' {
                    { $script:proxySettingsResult = ConvertFrom-ProxySettingsBinary -ProxySettings $script:proxyBinary -Verbose } | Should Not Throw
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