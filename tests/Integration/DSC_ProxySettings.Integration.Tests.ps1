[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }

    <#
        Need to define that variables here to be used in the Pester Discover to
        build the ForEach-blocks.
    #>
    $script:dscResourceFriendlyName = 'ProxySettings'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'NetworkingDsc'
    $script:dscResourceFriendlyName = 'ProxySettings'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

AfterAll {
    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Describe 'ProxySettings Integration Tests' {
    BeforeAll {
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile

        # Create a config data object to pass to the DSC Config
        $testProxyServer = 'testproxy:8888'
        $testProxyExceptions = 1..20 | Foreach-Object -Process {
            "exception$_.contoso.com"
        }
        $testAutoConfigURL = 'http://wpad.contoso.com/test.wpad'
    }

    AfterAll {
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
    }

    Context 'When Target is <_>' -ForEach  @('LocalMachine', 'CurrentUser') {
        Context "When Ensure is 'Present'" {
            BeforeAll {
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName                = 'localhost'
                            Target                  = $_
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
            }

            AfterEach {
                Wait-ForIdleLcm
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
            BeforeAll {
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName = 'localhost'
                            Target   = $_
                        }
                    )
                }
            }

            AfterEach {
                Wait-ForIdleLcm
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
