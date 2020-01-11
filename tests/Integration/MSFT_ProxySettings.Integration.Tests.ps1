$script:DSCModuleName      = 'NetworkingDsc'
$script:DSCResourceName    = 'MSFT_ProxySettings'

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

# Using try/finally to always cleanup even if something awful happens.
try
{
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

    Describe "$($script:DSCResourceName)_Present_Integration" {
        $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName)_Present.config.ps1"
        . $ConfigFile -Verbose -ErrorAction Stop

        It 'Should compile without throwing' {
            {
                & "$($script:DSCResourceName)_Present_Config" `
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
            $current = Get-DscConfiguration | Where-Object { $_.ConfigurationName -eq "$($script:DSCResourceName)_Present_Config" }
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

    Describe "$($script:DSCResourceName)_Absent_Integration" {
        $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName)_Absent.config.ps1"
        . $ConfigFile -Verbose -ErrorAction Stop

        It 'Should compile without throwing' {
            {
                & "$($script:DSCResourceName)_Absent_Config" `
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
            $current = Get-DscConfiguration | Where-Object { $_.ConfigurationName -eq "$($script:DSCResourceName)_Absent_Config" }
            $current.Ensure            | Should -Be 'Absent'
        }
    }
}
finally
{
    #region FOOTER

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

    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
