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

        $configData = @{
            AllNodes = @(
                @{
                    NodeName                = 'localhost'
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

        Describe "$($script:dscResourceName)_Present_Integration" {
            $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_Present.config.ps1"
            . $configFile -Verbose -ErrorAction Stop

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
                $script:currentState | Should -Be $true
            }

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object { $_.ConfigurationName -eq "$($script:dscResourceName)_Present_Config" }
                $current.Ensure                  | Should -Be 'Present'
                $current.EnableAutoDetection     | Should -Be $True
                $current.EnableAutoConfiguration | Should -Be $True
                $current.EnableManualProxy       | Should -Be $True
                $current.ProxyServer             | Should -Be $testProxyServer
                $current.ProxyServerExceptions   | Should -Be $testProxyExceptions
                $current.ProxyServerBypassLocal  | Should -Be $True
                $current.AutoConfigURL           | Should -Be $testAutoConfigURL
            }
        }

        Describe "$($script:dscResourceName)_Absent_Integration" {
            $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_Absent.config.ps1"
            . $configFile -Verbose -ErrorAction Stop

            It 'Should compile without throwing' {
                {
                    & "$($script:dscResourceName)_Absent_Config" `
                        -OutputPath $TestDrive

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
                $script:currentState | Should -Be $true
            }

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object { $_.ConfigurationName -eq "$($script:dscResourceName)_Absent_Config" }
                $current.Ensure            | Should -Be 'Absent'
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
