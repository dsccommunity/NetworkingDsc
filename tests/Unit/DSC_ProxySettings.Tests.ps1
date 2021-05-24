$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_ProxySettings'

function Invoke-TestSetup
{
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
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        $script:dscResourceName = 'DSC_ProxySettings'

        # Create the Mock Objects that will be used for running tests
        $testProxyServer = 'testproxy:8888'
        $testProxyExceptions = 1..20 | Foreach-Object -Process {
            "exception$_.contoso.com"
        }
        $testProxyAlternateExceptions = @('exception1.contoso.com')
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
            ProxyServerExceptions   = $testProxyExceptions
            EnableAutoConfiguration = $False
        }

        $testProxyManualProxyWithAlternateExceptionsSettings = [PSObject] @{
            EnableAutoDetection     = $False
            EnableManualProxy       = $True
            ProxyServer             = $testProxyServer
            ProxyServerExceptions   = $testProxyAlternateExceptions
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
            ProxyServerExceptions   = $testProxyExceptions
            EnableAutoConfiguration = $True
            AutoConfigURL           = $testAutoConfigURL
        }

        $testProxyAllEnabledWithBypassLocalSettings = [PSObject] @{
            EnableAutoDetection     = $True
            EnableManualProxy       = $True
            ProxyServer             = $testProxyServer
            ProxyServerBypassLocal  = $True
            ProxyServerExceptions   = $testProxyExceptions
            EnableAutoConfiguration = $True
            AutoConfigURL           = $testAutoConfigURL
        }

        $localMachineParameters = @{
            Target = 'LocalMachine'
            Verbose = $true
        }

        $currentUserParameters = @{
            Target = 'CurrentUser'
            Verbose = $true
        }

        [System.Byte[]] $testBinary = @(0x46, 0x0, 0x0, 0x0, 0x8, 0x0, 0x0, 0x0, 0x1, 0x0, 0x0, 0x0)

        Describe 'DSC_ProxySettings\Get-TargetResource' -Tag 'Get' {
            Context 'When no proxy settings are defined in the registry' {
                Mock `
                    -CommandName Get-ItemProperty `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:getTargetResourceResult = Get-TargetResource @localMachineParameters
                    } | Should -Not -Throw
                }

                It 'Should return the expected values' {
                    $script:getTargetResourceResult.Ensure | Should -Be 'Absent'
                }

                It 'Should call expected mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When the DefaultConnectionSettings proxy settings are defined in the registry' {
                Mock `
                    -CommandName Get-ItemProperty `
                    -MockWith {
                        @{
                            DefaultConnectionSettings = $testBinary
                        }
                    } `
                    -Verifiable

                Mock `
                    -CommandName ConvertFrom-ProxySettingsBinary `
                    -MockWith {
                    return $testProxyAllEnabledWithBypassLocalSettings
                } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:getTargetResourceResult = Get-TargetResource @localMachineParameters
                    } | Should -Not -Throw
                }

                It 'Should return the expected values' {
                    $script:getTargetResourceResult.Ensure | Should -Be 'Present'
                    $script:getTargetResourceResult.EnableAutoDetection | Should -Be $testProxyAllEnabledWithBypassLocalSettings.EnableAutoDetection
                    $script:getTargetResourceResult.EnableManualProxy | Should -Be $testProxyAllEnabledWithBypassLocalSettings.EnableManualProxy
                    $script:getTargetResourceResult.ProxyServer | Should -Be $testProxyAllEnabledWithBypassLocalSettings.ProxyServer
                    $script:getTargetResourceResult.ProxyServerBypassLocal | Should -Be $testProxyAllEnabledWithBypassLocalSettings.ProxyServerBypassLocal
                    $script:getTargetResourceResult.ProxyServerExceptions | Should -Be $testProxyAllEnabledWithBypassLocalSettings.ProxyServerExceptions
                    $script:getTargetResourceResult.EnableAutoConfiguration | Should -Be $testProxyAllEnabledWithBypassLocalSettings.EnableAutoConfiguration
                    $script:getTargetResourceResult.AutoConfigURL | Should -Be $testProxyAllEnabledWithBypassLocalSettings.AutoConfigURL
                }

                It 'Should call expected mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When the SavedLegacySettings proxy settings are defined in the registry' {
                Mock `
                    -CommandName Get-ItemProperty `
                    -MockWith {
                        @{
                            SavedLegacySettings = $testBinary
                        }
                    } `
                    -Verifiable

                Mock `
                    -CommandName ConvertFrom-ProxySettingsBinary `
                    -MockWith {
                    return $testProxyAllEnabledWithBypassLocalSettings
                } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:getTargetResourceResult = Get-TargetResource @localMachineParameters
                    } | Should -Not -Throw
                }

                It 'Should return the expected values' {
                    $script:getTargetResourceResult.Ensure | Should -Be 'Present'
                    $script:getTargetResourceResult.EnableAutoDetection | Should -Be $testProxyAllEnabledWithBypassLocalSettings.EnableAutoDetection
                    $script:getTargetResourceResult.EnableManualProxy | Should -Be $testProxyAllEnabledWithBypassLocalSettings.EnableManualProxy
                    $script:getTargetResourceResult.ProxyServer | Should -Be $testProxyAllEnabledWithBypassLocalSettings.ProxyServer
                    $script:getTargetResourceResult.ProxyServerBypassLocal | Should -Be $testProxyAllEnabledWithBypassLocalSettings.ProxyServerBypassLocal
                    $script:getTargetResourceResult.ProxyServerExceptions | Should -Be $testProxyAllEnabledWithBypassLocalSettings.ProxyServerExceptions
                    $script:getTargetResourceResult.EnableAutoConfiguration | Should -Be $testProxyAllEnabledWithBypassLocalSettings.EnableAutoConfiguration
                    $script:getTargetResourceResult.AutoConfigURL | Should -Be $testProxyAllEnabledWithBypassLocalSettings.AutoConfigURL
                }

                It 'Should call expected mocks' {
                    Assert-VerifiableMock
                }
            }
        }

        Describe 'DSC_ProxySettings\Set-TargetResource' -Tag 'Set' {
            Context 'When ensuring proxy settings not defined for All Connection types' {
                Mock `
                    -CommandName Remove-ItemProperty `
                    -ParameterFilter { $Name -eq 'DefaultConnectionSettings' }

                Mock `
                    -CommandName Remove-ItemProperty `
                    -ParameterFilter { $Name -eq 'SavedLegacySettings' }

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource @localMachineParameters -Ensure 'Absent' -ConnectionType 'All'
                    } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Remove-ItemProperty `
                        -ParameterFilter { $Name -eq 'DefaultConnectionSettings' } `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Remove-ItemProperty `
                        -ParameterFilter { $Name -eq 'SavedLegacySettings' } `
                        -Exactly -Times 1
                }
            }

            Context 'When ensuring proxy settings not defined for Default Connection type' {
                Mock `
                    -CommandName Remove-ItemProperty `
                    -ParameterFilter { $Name -eq 'DefaultConnectionSettings' }

                Mock `
                    -CommandName Remove-ItemProperty `
                    -ParameterFilter { $Name -eq 'SavedLegacySettings' }

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource @localMachineParameters -Ensure 'Absent' -ConnectionType 'Default'
                    } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Remove-ItemProperty `
                        -ParameterFilter { $Name -eq 'DefaultConnectionSettings' } `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Remove-ItemProperty `
                        -ParameterFilter { $Name -eq 'SavedLegacySettings' } `
                        -Exactly -Times 0
                }
            }

            Context 'When ensuring proxy settings not defined for Legacy Connection type' {
                Mock `
                    -CommandName Remove-ItemProperty `
                    -ParameterFilter { $Name -eq 'DefaultConnectionSettings' }

                Mock `
                    -CommandName Remove-ItemProperty `
                    -ParameterFilter { $Name -eq 'SavedLegacySettings' }

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource @localMachineParameters -Ensure 'Absent' -ConnectionType 'Legacy'
                    } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Remove-ItemProperty `
                        -ParameterFilter { $Name -eq 'DefaultConnectionSettings' } `
                        -Exactly -Times 0

                    Assert-MockCalled `
                        -CommandName Remove-ItemProperty `
                        -ParameterFilter { $Name -eq 'SavedLegacySettings' } `
                        -Exactly -Times 1
                }
            }

            Context 'When ensuring proxy settings are defined for All Connection types' {
                Mock `
                    -CommandName Set-BinaryRegistryValue `
                    -ParameterFilter { $Name -eq 'DefaultConnectionSettings' }

                Mock `
                    -CommandName Set-BinaryRegistryValue `
                    -ParameterFilter { $Name -eq 'SavedLegacySettings' }

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource @localMachineParameters -Ensure 'Present' -ConnectionType 'All'
                    } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Set-BinaryRegistryValue `
                        -ParameterFilter { $Name -eq 'DefaultConnectionSettings' } `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Set-BinaryRegistryValue `
                        -ParameterFilter { $Name -eq 'SavedLegacySettings' } `
                        -Exactly -Times 1
                }
            }

            Context 'When ensuring proxy settings are defined for Default Connection type' {
                Mock `
                    -CommandName Set-BinaryRegistryValue `
                    -ParameterFilter { $Name -eq 'DefaultConnectionSettings' }

                Mock `
                    -CommandName Set-BinaryRegistryValue `
                    -ParameterFilter { $Name -eq 'SavedLegacySettings' }

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource @localMachineParameters -Ensure 'Present' -ConnectionType 'Default'
                    } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Set-BinaryRegistryValue `
                        -ParameterFilter { $Name -eq 'DefaultConnectionSettings' } `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Set-BinaryRegistryValue `
                        -ParameterFilter { $Name -eq 'SavedLegacySettings' } `
                        -Exactly -Times 0
                }
            }

            Context 'When ensuring proxy settings are defined for Legacy Connection type' {
                Mock `
                    -CommandName Set-BinaryRegistryValue `
                    -ParameterFilter { $Name -eq 'DefaultConnectionSettings' }

                Mock `
                    -CommandName Set-BinaryRegistryValue `
                    -ParameterFilter { $Name -eq 'SavedLegacySettings' }

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource @localMachineParameters -Ensure 'Present' -ConnectionType 'Legacy'
                    } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Set-BinaryRegistryValue `
                        -ParameterFilter { $Name -eq 'DefaultConnectionSettings' } `
                        -Exactly -Times 0

                    Assert-MockCalled `
                        -CommandName Set-BinaryRegistryValue `
                        -ParameterFilter { $Name -eq 'SavedLegacySettings' } `
                        -Exactly -Times 1
                }
            }
        }

        Describe 'DSC_ProxySettings\Test-TargetResource' -Tag 'Test' {
            Context 'When no proxy settings are defined in the registry and None Required for All Connection types' {
                Mock `
                    -CommandName Get-ItemProperty `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:testTargetResourceResult = Test-TargetResource @localMachineParameters -Ensure 'Absent' -ConnectionType 'All'
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:testTargetResourceResult | Should -Be $True
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-ItemProperty `
                        -Exactly -Times 1
                }
            }

            Context 'When DefaultConnectionSettings are defined in the registry and None Required for All Connection types' {
                Mock `
                    -CommandName Get-ItemProperty `
                    -MockWith {
                        @{
                            DefaultConnectionSettings = $testBinary
                        }
                    } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:testTargetResourceResult = Test-TargetResource @localMachineParameters -Ensure 'Absent' -ConnectionType 'All'
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:testTargetResourceResult | Should -Be $False
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-ItemProperty `
                        -Exactly -Times 1
                }
            }

            Context 'When DefaultConnectionSettings are defined in the registry and None Required for Legacy Connection types' {
                Mock `
                    -CommandName Get-ItemProperty `
                    -MockWith {
                        @{
                            DefaultConnectionSettings = $testBinary
                        }
                    } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:testTargetResourceResult = Test-TargetResource @localMachineParameters -Ensure 'Absent' -ConnectionType 'Legacy'
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:testTargetResourceResult | Should -Be $True
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-ItemProperty `
                        -Exactly -Times 1
                }
            }

            Context 'When SavedLegacySettings are defined in the registry and None Required for All Connection types' {
                Mock `
                    -CommandName Get-ItemProperty `
                    -MockWith {
                        @{
                            SavedLegacySettings = $testBinary
                        }
                    } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:testTargetResourceResult = Test-TargetResource @localMachineParameters -Ensure 'Absent' -ConnectionType 'All'
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:testTargetResourceResult | Should -Be $False
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-ItemProperty `
                        -Exactly -Times 1
                }
            }

            Context 'When SavedLegacySettings are defined in the registry and None Required for Default Connection types' {
                Mock `
                    -CommandName Get-ItemProperty `
                    -MockWith {
                        @{
                            SavedLegacySettings = $testBinary
                        }
                    } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:testTargetResourceResult = Test-TargetResource @localMachineParameters -Ensure 'Absent' -ConnectionType 'Default'
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:testTargetResourceResult | Should -Be $True
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-ItemProperty `
                        -Exactly -Times 1
                }
            }

            Context 'When DefaultConnectionSettings are defined in the registry but are Different for Default Connection type' {
                Mock `
                    -CommandName Get-ItemProperty `
                    -MockWith {
                        @{
                            DefaultConnectionSettings = $testBinary
                        }
                    } `
                    -Verifiable

                Mock `
                    -CommandName Test-ProxySettings `
                    -MockWith { $false } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:testTargetResourceResult = Test-TargetResource @localMachineParameters -Ensure 'Present' -ConnectionType 'Default'
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:testTargetResourceResult | Should -Be $False
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-ItemProperty `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Test-ProxySettings `
                        -Exactly -Times 1
                }
            }

            Context 'When SavedLegacySettings are defined in the registry but are Different for Legacy Connection type' {
                Mock `
                    -CommandName Get-ItemProperty `
                    -MockWith {
                        @{
                            SavedLegacySettings = $testBinary
                        }
                    } `
                    -Verifiable

                Mock `
                    -CommandName Test-ProxySettings `
                    -MockWith { $false } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:testTargetResourceResult = Test-TargetResource @localMachineParameters -Ensure 'Present' -ConnectionType 'Legacy'
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:testTargetResourceResult | Should -Be $False
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-ItemProperty `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Test-ProxySettings `
                        -Exactly -Times 1
                }
            }

            Context 'When DefaultConnectionSettings are defined in the registry and matches for Default Connection type' {
                Mock `
                    -CommandName Get-ItemProperty `
                    -MockWith {
                        @{
                            DefaultConnectionSettings = $testBinary
                        }
                    } `
                    -Verifiable

                Mock `
                    -CommandName Test-ProxySettings `
                    -MockWith { $true } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:testTargetResourceResult = Test-TargetResource @localMachineParameters -Ensure 'Present' -ConnectionType 'Default'
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:testTargetResourceResult | Should -Be $True
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-ItemProperty `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Test-ProxySettings `
                        -Exactly -Times 1
                }
            }

            Context 'When SavedLegacySettings are defined in the registry and matches for Legacy Connection type' {
                Mock `
                    -CommandName Get-ItemProperty `
                    -MockWith {
                        @{
                            SavedLegacySettings = $testBinary
                        }
                    } `
                    -Verifiable

                Mock `
                    -CommandName Test-ProxySettings `
                    -MockWith { $true } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:testTargetResourceResult = Test-TargetResource @localMachineParameters -Ensure 'Present' -ConnectionType 'Legacy'
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:testTargetResourceResult | Should -Be $True
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-ItemProperty `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Test-ProxySettings `
                        -Exactly -Times 1
                }
            }

            Context 'When DefaultConnectionSettings are defined in the registry but Legacy Connection Type settings required' {
                Mock `
                    -CommandName Get-ItemProperty `
                    -MockWith {
                        @{
                            DefaultConnectionSettings = $testBinary
                        }
                    } `
                    -Verifiable

                Mock `
                    -CommandName Test-ProxySettings `
                    -MockWith { $false } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:testTargetResourceResult = Test-TargetResource @localMachineParameters -Ensure 'Present' -ConnectionType 'Legacy'
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:testTargetResourceResult | Should -Be $False
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-ItemProperty `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Test-ProxySettings `
                        -Exactly -Times 1
                }
            }

            Context 'When DefaultConnectionSettings are defined in the registry but Default Connection Type settings required' {
                Mock `
                    -CommandName Get-ItemProperty `
                    -MockWith {
                        @{
                            SavedLegacySettings = $testBinary
                        }
                    } `
                    -Verifiable

                Mock `
                    -CommandName Test-ProxySettings `
                    -MockWith { $false } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:testTargetResourceResult = Test-TargetResource @localMachineParameters -Ensure 'Present' -ConnectionType 'Default'
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:testTargetResourceResult | Should -Be $False
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-ItemProperty `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Test-ProxySettings `
                        -Exactly -Times 1
                }
            }
        }

        Describe 'DSC_ProxySettings\Test-ProxySettings' {
            Context 'When all proxy types are Disabled' {
                It 'Should not throw an exception' {
                    { $script:testProxySettingsResult = Test-ProxySettings `
                            -CurrentValues $testProxyAllDisabledSettings `
                            -DesiredValues $testProxyAllDisabledSettings `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:testProxySettingsResult | Should -Be $true
                }
            }

            Context 'When all proxy types are Enabled and Proxy Bypass Local is Disabled with all Values matching' {
                It 'Should not throw an exception' {
                    { $script:testProxySettingsResult = Test-ProxySettings `
                            -CurrentValues $testProxyAllEnabledWithoutBypassLocalSettings `
                            -DesiredValues $testProxyAllEnabledWithoutBypassLocalSettings `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:testProxySettingsResult | Should -Be $true
                }
            }

            Context 'When all proxy types Enabled and Proxy Bypass Local Enabled with all Values matching' {
                It 'Should not throw an exception' {
                    { $script:testProxySettingsResult = Test-ProxySettings `
                            -CurrentValues $testProxyAllEnabledWithBypassLocalSettings `
                            -DesiredValues $testProxyAllEnabledWithBypassLocalSettings `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:testProxySettingsResult | Should -Be $true
                }
            }

            Context 'When all proxy types Enabled and Proxy Bypass Local Enabled with Bypass Local not matching' {
                It 'Should not throw an exception' {
                    { $script:testProxySettingsResult = Test-ProxySettings `
                            -CurrentValues $testProxyAllEnabledWithBypassLocalSettings `
                            -DesiredValues $testProxyAllEnabledWithoutBypassLocalSettings `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:testProxySettingsResult | Should -Be $false
                }
            }

            Context 'When only Manual Proxy Server type Enabled with Exceptions Only that match' {
                It 'Should not throw an exception' {
                    { $script:testProxySettingsResult = Test-ProxySettings `
                            -CurrentValues $testProxyManualProxyWithExceptionsSettings `
                            -DesiredValues $testProxyManualProxyWithExceptionsSettings `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:testProxySettingsResult | Should -Be $true
                }
            }

            Context 'When only Manual Proxy Server type Enabled with Exceptions Only that do not match' {
                It 'Should not throw an exception' {
                    { $script:testProxySettingsResult = Test-ProxySettings `
                            -CurrentValues $testProxyManualProxyWithExceptionsSettings `
                            -DesiredValues $testProxyManualProxyWithAlternateExceptionsSettings `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:testProxySettingsResult | Should -Be $false
                }
            }
        }

        Describe 'DSC_ProxySettings\Get-StringLengthInHexBytes' {
            Context 'When an empty value string is passed' {
                It 'Should return @(0x00,0x00,0x00,0x00)' {
                    Get-StringLengthInHexBytes -Value '' | Should -Be @( '0x00', '0x00', '0x00', '0x00' )
                }
            }

            Context 'When a value string less than 256 characters is passed' {
                It 'Should return @(0xFF,0x00,0x00,0x00)' {
                    Get-StringLengthInHexBytes -Value ([System.String]::new('a', 255)) | Should -Be @( '0xFF', '0x00', '0x00', '0x00' )
                }
            }

            Context 'When a value string more than 256 characters is passed' {
                It 'Should return @(0x01,0x01,0x00,0x00)' {
                    Get-StringLengthInHexBytes -Value ([System.String]::new('a', 257)) | Should -Be @( '0x01', '0x01', '0x00', '0x00' )
                }
            }
        }

        Describe 'DSC_ProxySettings\Get-Int32FromByteArray' {
            Context 'When a byte array with a little endian integer less than 256 starting at byte 0' {
                It 'Should return 255' {
                    Get-Int32FromByteArray -Byte ([System.Byte[]] @(255, 0, 0, 0, 99)) -StartByte 0 | Should -Be 255
                }
            }

            Context 'When a byte array with a little endian integer less than 256 starting at byte 1' {
                It 'Should return 255' {
                    Get-Int32FromByteArray -Byte ([System.Byte[]] @(99, 255, 0, 0, 0, 99)) -StartByte 1 | Should -Be 255
                }
            }

            Context 'When a byte array with a little endian integer more than 256 starting at byte 0' {
                It 'Should return 256' {
                    Get-Int32FromByteArray -Byte ([System.Byte[]] @(1, 1, 0, 0, 99)) -StartByte 0 | Should -Be 257
                }
            }

            Context 'When a byte array with a little endian integer more than 256 starting at byte 1' {
                It 'Should return 256' {
                    Get-Int32FromByteArray -Byte ([System.Byte[]] @(99, 1, 1, 0, 0, 99)) -StartByte 1 | Should -Be 257
                }
            }
        }

        Describe 'DSC_ProxySettings\Convert*-ProxySettingsBinary' {
            Context 'When all proxy types are Disabled' {
                It 'Should not throw an exception when converting to proxy settings Binary' {
                    { $script:proxyBinary = ConvertTo-ProxySettingsBinary @testProxyAllDisabledSettings -Verbose } | Should -Not -Throw
                }

                It 'Should not throw an exception when converting from proxy settings Binary' {
                    { $script:proxySettingsResult = ConvertFrom-ProxySettingsBinary -ProxySettings $script:proxyBinary -Verbose } | Should -Not -Throw
                }

                It 'Should convert the values to binary and back to source values correctly' {
                    $script:proxySettingsResult.EnableAutoDetection | Should -Be $testProxyAllDisabledSettings.EnableAutoDetection
                    $script:proxySettingsResult.EnableManualProxy | Should -Be $testProxyAllDisabledSettings.EnableManualProxy
                    $script:proxySettingsResult.ProxyServer | Should -BeNullOrEmpty
                    $script:proxySettingsResult.ProxyServerBypassLocal | Should -Be $False
                    $script:proxySettingsResult.ProxyServerExceptions | Should -BeNullOrEmpty
                    $script:proxySettingsResult.EnableAutoConfiguration | Should -Be $testProxyAllDisabledSettings.EnableAutoConfiguration
                    $script:proxySettingsResult.AutoConfigURL | Should -BeNullOrEmpty
                }
            }

            Context 'When only Manual Proxy Server type Enabled' {
                It 'Should not throw an exception when converting to proxy settings Binary' {
                    { $script:proxyBinary = ConvertTo-ProxySettingsBinary @testProxyManualProxySettings -Verbose } | Should -Not -Throw
                }

                It 'Should not throw an exception when converting from proxy settings Binary' {
                    { $script:proxySettingsResult = ConvertFrom-ProxySettingsBinary -ProxySettings $script:proxyBinary -Verbose } | Should -Not -Throw
                }

                It 'Should convert the values to binary and back to source values correctly' {
                    $script:proxySettingsResult.EnableAutoDetection | Should -Be $testProxyManualProxySettings.EnableAutoDetection
                    $script:proxySettingsResult.EnableManualProxy | Should -Be $testProxyManualProxySettings.EnableManualProxy
                    $script:proxySettingsResult.ProxyServer | Should -Be $testProxyManualProxySettings.ProxyServer
                    $script:proxySettingsResult.ProxyServerBypassLocal | Should -Be $False
                    $script:proxySettingsResult.ProxyServerExceptions | Should -BeNullOrEmpty
                    $script:proxySettingsResult.EnableAutoConfiguration | Should -Be $testProxyManualProxySettings.EnableAutoConfiguration
                    $script:proxySettingsResult.AutoConfigURL | Should -BeNullOrEmpty
                }
            }

            Context 'When only Manual Proxy Server type Enabled with Exceptions Only' {
                It 'Should not throw an exception when converting to proxy settings Binary' {
                    { $script:proxyBinary = ConvertTo-ProxySettingsBinary @testProxyManualProxyWithExceptionsSettings -Verbose } | Should -Not -Throw
                }

                It 'Should not throw an exception when converting from proxy settings Binary' {
                    { $script:proxySettingsResult = ConvertFrom-ProxySettingsBinary -ProxySettings $script:proxyBinary -Verbose } | Should -Not -Throw
                }

                It 'Should convert the values to binary and back to source values correctly' {
                    $script:proxySettingsResult.EnableAutoDetection | Should -Be $testProxyManualProxyWithExceptionsSettings.EnableAutoDetection
                    $script:proxySettingsResult.EnableManualProxy | Should -Be $testProxyManualProxyWithExceptionsSettings.EnableManualProxy
                    $script:proxySettingsResult.ProxyServer | Should -Be $testProxyManualProxyWithExceptionsSettings.ProxyServer
                    $script:proxySettingsResult.ProxyServerBypassLocal | Should -Be $False
                    $script:proxySettingsResult.ProxyServerExceptions | Should -Be $testProxyManualProxyWithExceptionsSettings.ProxyServerExceptions
                    $script:proxySettingsResult.EnableAutoConfiguration | Should -Be $testProxyManualProxyWithExceptionsSettings.EnableAutoConfiguration
                    $script:proxySettingsResult.AutoConfigURL | Should -BeNullOrEmpty
                }
            }

            Context 'When only Manual Proxy Server type Enabled with Bypass Local Only' {
                It 'Should not throw an exception when converting to proxy settings Binary' {
                    { $script:proxyBinary = ConvertTo-ProxySettingsBinary @testProxyManualProxyWithBypassLocalOnlySettings -Verbose } | Should -Not -Throw
                }

                It 'Should not throw an exception when converting from proxy settings Binary' {
                    { $script:proxySettingsResult = ConvertFrom-ProxySettingsBinary -ProxySettings $script:proxyBinary -Verbose } | Should -Not -Throw
                }

                It 'Should convert the values to binary and back to source values correctly' {
                    $script:proxySettingsResult.EnableAutoDetection | Should -Be $testProxyManualProxyWithBypassLocalOnlySettings.EnableAutoDetection
                    $script:proxySettingsResult.EnableManualProxy | Should -Be $testProxyManualProxyWithBypassLocalOnlySettings.EnableManualProxy
                    $script:proxySettingsResult.ProxyServer | Should -Be $testProxyManualProxyWithBypassLocalOnlySettings.ProxyServer
                    $script:proxySettingsResult.ProxyServerBypassLocal | Should -Be $True
                    $script:proxySettingsResult.ProxyServerExceptions | Should -BeNullOrEmpty
                    $script:proxySettingsResult.EnableAutoConfiguration | Should -Be $testProxyManualProxyWithBypassLocalOnlySettings.EnableAutoConfiguration
                    $script:proxySettingsResult.AutoConfigURL | Should -BeNullOrEmpty
                }
            }

            Context 'When only Auto Config Proxy type Enabled' {
                It 'Should not throw an exception when converting to proxy settings Binary' {
                    { $script:proxyBinary = ConvertTo-ProxySettingsBinary @testProxyAutoConfigOnlySettings -Verbose } | Should -Not -Throw
                }

                It 'Should not throw an exception when converting from proxy settings Binary' {
                    { $script:proxySettingsResult = ConvertFrom-ProxySettingsBinary -ProxySettings $script:proxyBinary -Verbose } | Should -Not -Throw
                }

                It 'Should convert the values to binary and back to source values correctly' {
                    $script:proxySettingsResult.EnableAutoDetection | Should -Be $testProxyAutoConfigOnlySettings.EnableAutoDetection
                    $script:proxySettingsResult.EnableManualProxy | Should -Be $testProxyAutoConfigOnlySettings.EnableManualProxy
                    $script:proxySettingsResult.ProxyServer | Should -BeNullOrEmpty
                    $script:proxySettingsResult.ProxyServerBypassLocal | Should -Be $False
                    $script:proxySettingsResult.ProxyServerExceptions | Should -BeNullOrEmpty
                    $script:proxySettingsResult.EnableAutoConfiguration | Should -Be $testProxyAutoConfigOnlySettings.EnableAutoConfiguration
                    $script:proxySettingsResult.AutoConfigURL | Should -Be $testProxyAutoConfigOnlySettings.AutoConfigURL
                }
            }

            Context 'When all Proxy Types Enabled and Proxy Bypass Local Disabled' {
                It 'Should not throw an exception when converting to proxy settings Binary' {
                    { $script:proxyBinary = ConvertTo-ProxySettingsBinary @testProxyAllEnabledWithoutBypassLocalSettings -Verbose } | Should -Not -Throw
                }

                It 'Should not throw an exception when converting from proxy settings Binary' {
                    { $script:proxySettingsResult = ConvertFrom-ProxySettingsBinary -ProxySettings $script:proxyBinary -Verbose } | Should -Not -Throw
                }

                It 'Should convert the values to binary and back to source values correctly' {
                    $script:proxySettingsResult.EnableAutoDetection | Should -Be $testProxyAllEnabledWithoutBypassLocalSettings.EnableAutoDetection
                    $script:proxySettingsResult.EnableManualProxy | Should -Be $testProxyAllEnabledWithoutBypassLocalSettings.EnableManualProxy
                    $script:proxySettingsResult.ProxyServer | Should -Be $testProxyAllEnabledWithoutBypassLocalSettings.ProxyServer
                    $script:proxySettingsResult.ProxyServerBypassLocal | Should -Be $testProxyAllEnabledWithoutBypassLocalSettings.ProxyServerBypassLocal
                    $script:proxySettingsResult.ProxyServerExceptions | Should -Be $testProxyAllEnabledWithoutBypassLocalSettings.ProxyServerExceptions
                    $script:proxySettingsResult.EnableAutoConfiguration | Should -Be $testProxyAllEnabledWithoutBypassLocalSettings.EnableAutoConfiguration
                    $script:proxySettingsResult.AutoConfigURL | Should -Be $testProxyAllEnabledWithoutBypassLocalSettings.AutoConfigURL
                }
            }

            Context 'When all Proxy Types Enabled and Proxy Bypass Local Enabled' {
                It 'Should not throw an exception when converting to proxy settings Binary' {
                    { $script:proxyBinary = ConvertTo-ProxySettingsBinary @testProxyAllEnabledWithBypassLocalSettings -Verbose } | Should -Not -Throw
                }

                It 'Should not throw an exception when converting from proxy settings Binary' {
                    { $script:proxySettingsResult = ConvertFrom-ProxySettingsBinary -ProxySettings $script:proxyBinary -Verbose } | Should -Not -Throw
                }

                It 'Should convert the values to binary and back to source values correctly' {
                    $script:proxySettingsResult.EnableAutoDetection | Should -Be $testProxyAllEnabledWithBypassLocalSettings.EnableAutoDetection
                    $script:proxySettingsResult.EnableManualProxy | Should -Be $testProxyAllEnabledWithBypassLocalSettings.EnableManualProxy
                    $script:proxySettingsResult.ProxyServer | Should -Be $testProxyAllEnabledWithBypassLocalSettings.ProxyServer
                    $script:proxySettingsResult.ProxyServerBypassLocal | Should -Be $testProxyAllEnabledWithBypassLocalSettings.ProxyServerBypassLocal
                    $script:proxySettingsResult.ProxyServerExceptions | Should -Be $testProxyAllEnabledWithBypassLocalSettings.ProxyServerExceptions
                    $script:proxySettingsResult.EnableAutoConfiguration | Should -Be $testProxyAllEnabledWithBypassLocalSettings.EnableAutoConfiguration
                    $script:proxySettingsResult.AutoConfigURL | Should -Be $testProxyAllEnabledWithBypassLocalSettings.AutoConfigURL
                }
            }
        }

        Describe 'DSC_ProxySettings\Get-ProxySettingsRegistryKeyPath' {
            Context 'When target is default (LocalMachine)' {
                It 'Should return "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections"' {
                    Get-ProxySettingsRegistryKeyPath | Should -BeExactly 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections'
                }
            }

            Context 'When target is CurrentUser' {
                It 'Should return "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Connections"' {
                    Get-ProxySettingsRegistryKeyPath -Target 'CurrentUser' | Should -BeExactly 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Connections'
                }
            }
        }

        Describe 'DSC_ProxySettings\ConvertTo-Win32RegistryPath' {
            Context 'When path contains "HKLM:\SOFTWARE"' {
                It 'Should return "HKEY_LOCAL_MACHINE\SOFTWARE"' {
                    ConvertTo-Win32RegistryPath -Path 'HKLM:\SOFTWARE' | Should -Be 'HKEY_LOCAL_MACHINE\SOFTWARE'
                }
            }

            Context 'When path contains "HKCU:\SOFTWARE"' {
                It 'Should return "HKEY_CURRENT_USER\SOFTWARE"' {
                    ConvertTo-Win32RegistryPath -Path 'HKCU:\Software' | Should -Be 'HKEY_CURRENT_USER\Software'
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
