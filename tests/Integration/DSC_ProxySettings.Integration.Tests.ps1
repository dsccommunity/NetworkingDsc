$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_ProxySettings'

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
    Describe 'ProxySettings Integration Tests' {
        # Create a config data object to pass to the DSC Config
        $testProxyServer = 'testproxy:8888'
        $testProxyExceptions = 1..20 | Foreach-Object -Process {
            "exception$_.contoso.com"
        }
        $testAutoConfigURL = 'http://wpad.contoso.com/test.wpad'

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile -Verbose -ErrorAction Stop

        foreach ($target in @('LocalMachinee','CurrentUser'))
        {
            Context "When Target is '$Target'" {
                Context "When Ensure is 'Present'" {
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName                = 'localhost'
                                Target                  = $Target
                                EnableAutoDetection     = $True
                                EnableAutoConfiguration = $True
                                EnableManualProxy       = $True
                                ProxyServer             = $testProxyServer
                                ProxyServerExceptions   = $testProxyExceptions
                                ProxyServerBypassLocal  = $True
                                AutoConfigURL           = $testAutoConfigURL
                            }
                        )
                    }

                    It 'Should compile without throwing' {
                        {
                            & "$($script:dscResourceName)_Present_Config" `
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

                    It 'Should be able to call Get-DscConfiguration without throwing' {
                        { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                    }

                    It 'Should be able to call Test-DscConfiguration without throwing' {
                        { $script:currentState = Test-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                    }

                    It 'Should report that DSC is in state' {
                        $script:currentState | Should -BeTrue
                    }

                    It 'Should have set the resource and all the parameters should match' {
                        $current = Get-DscConfiguration | Where-Object {
                            $_.ConfigurationName -eq "$($script:dscResourceName)_Present_Config"
                        }
                        $current.Ensure                  | Should -Be 'Present'
                        $current.Target                  | Should -Be $configData.AllNodes[0].Target
                        $current.EnableAutoDetection     | Should -Be $configData.AllNodes[0].EnableAutoDetection
                        $current.EnableAutoConfiguration | Should -Be $configData.AllNodes[0].EnableAutoConfiguration
                        $current.EnableManualProxy       | Should -Be $configData.AllNodes[0].EnableManualProxy
                        $current.ProxyServer             | Should -Be $configData.AllNodes[0].ProxyServer
                        $current.ProxyServerExceptions   | Should -Be $configData.AllNodes[0].ProxyServerExceptions
                        $current.ProxyServerBypassLocal  | Should -Be $configData.AllNodes[0].ProxyServerBypassLocal
                        $current.AutoConfigURL           | Should -Be $configData.AllNodes[0].AutoConfigURL
                    }
                }

                Context "When Ensure is 'Absent'" {
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName = 'localhost'
                                Target   = $Target
                            }
                        )
                    }

                    It 'Should compile without throwing' {
                        {
                            & "$($script:dscResourceName)_Absent_Config" `
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

                    It 'Should be able to call Get-DscConfiguration without throwing' {
                        { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                    }

                    It 'Should be able to call Test-DscConfiguration without throwing' {
                        { $script:currentState = Test-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                    }

                    It 'Should report that DSC is in state' {
                        $script:currentState | Should -BeTrue
                    }

                    It 'Should have set the resource and all the parameters should match' {
                        $current = Get-DscConfiguration | Where-Object {
                            $_.ConfigurationName -eq "$($script:dscResourceName)_Absent_Config"
                        }
                        $current.Ensure | Should -Be 'Absent'
                        $current.Target | Should -Be $configData.AllNodes[0].Target
                    }
                }
            }
        }
    }
}
finally
{
    # Clean up any proxy settings in case the tests fail
    $connectionsRegistryKeyPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections'

    Remove-ItemProperty `
        -Path "HKLM:\$($connectionsRegistryKeyPath)" `
        -Name 'DefaultConnectionSettings' `
        -ErrorAction SilentlyContinue

    Remove-ItemProperty `
        -Path "HKLM:\$($connectionsRegistryKeyPath)" `
        -Name 'SavedLegacySettings' `
        -ErrorAction SilentlyContinue

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
