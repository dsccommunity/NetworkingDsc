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
    $script:dscResourceFriendlyName = 'NetBios'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'NetworkingDsc'
    $script:dscResourceFriendlyName = 'NetBios'
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

Describe 'NetBios Integration Tests' {
    BeforeAll {
        # Check NetBiosSetting enum loaded, if not load
        try
        {
            [void][System.Reflection.Assembly]::GetAssembly([NetBiosSetting])
        }
        catch
        {
            Add-Type -TypeDefinition @'
public enum NetBiosSetting
{
    Default,
    Enable,
    Disable
}
'@
        }

        # Configure Loopback Adapters
        New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA1'
        New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA2'

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile
    }

    AfterAll {
        # Remove Loopback Adapters
        Remove-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA2'
        Remove-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA1'
    }

    Describe "$($script:dscResourceName)_Integration" {
        Context 'When applying to a single network adapter' {
            BeforeDiscovery {
                $testCases = @(
                    @{
                        InterfaceAlias = 'NetworkingDscLBA1'
                        Setting        = 'Disable'
                    }
                    @{
                        InterfaceAlias = 'NetworkingDscLBA1'
                        Setting        = 'Enable'
                    }
                    @{
                        InterfaceAlias = 'NetworkingDscLBA1'
                        Setting        = 'Default'
                    }
                )
            }

            Context 'When setting NetBios over TCP/IP to <Setting>' -ForEach $testCases {
                BeforeAll {
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName       = 'localhost'
                                InterfaceAlias = $InterfaceAlias
                                Setting        = $Setting
                            }
                        )
                    }
                }

                AfterEach {
                    Wait-ForIdleLcm
                }

                It 'Should compile and apply the MOF without throwing' {
                    {
                        & "$($script:dscResourceName)_Config" `
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

                It 'Should have set the resource and all settings should match current state' {
                    $result = Get-DscConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                    }

                    $result.Setting | Should -Be $Setting
                }
            }
        }

        Context 'When applying to a all network adapters' {
            BeforeDiscovery {
                $testCases = @(
                    @{
                        InterfaceAlias = 'NetworkingDscLBA*'
                        Setting        = 'Disable'
                    }
                    @{
                        InterfaceAlias = 'NetworkingDscLBA*'
                        Setting        = 'Enable'
                    }
                    @{
                        InterfaceAlias = 'NetworkingDscLBA*'
                        Setting        = 'Default'
                    }
                )
            }

            Context 'When setting NetBios over TCP/IP to <Setting>' -ForEach $testCases {
                BeforeAll {
                    # Fix intermittent test failures
                    Wait-ForIdleLcm -Clear

                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName       = 'localhost'
                                InterfaceAlias = $InterfaceAlias
                                Setting        = $Setting
                            }
                        )
                    }
                }

                AfterEach {
                    Wait-ForIdleLcm
                }

                It 'Should compile and apply the MOF without throwing' {
                    {
                        & "$($script:dscResourceName)_Config" `
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

                It 'Should have set the resource and all setting should match current state' {
                    $result = Get-DscConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                    }

                    $result.Setting | Should -Be $Setting
                }
            }
        }
    }
}
