$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_NetBios'

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
    Describe 'NetBios Integration Tests' {
        # Configure Loopback Adapters
        $netAdapter1 = New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA1'
        $netAdapter2 = New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA2'

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile -Verbose -ErrorAction Stop

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

        # Ensure the Net Bios setting is in a known state (enabled)
        $null = $netAdapter1 | Invoke-CimMethod `
            -MethodName SetTcpipNetbios `
            -ErrorAction Stop `
            -Arguments @{
                TcpipNetbiosOptions = [uint32][NetBiosSetting]::Enable
            }
        $null = $netAdapter2 | Invoke-CimMethod `
            -MethodName SetTcpipNetbios `
            -ErrorAction Stop `
            -Arguments @{
                TcpipNetbiosOptions = [uint32][NetBiosSetting]::Enable
            }

        Describe "$($script:dscResourceName)_Integration" {
            Context 'Disable NetBios over TCP/IP' {
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName            = 'localhost'
                            InterfaceAlias      = $netAdapter1.NetConnectionID
                            Setting             = 'Disable'
                        }
                    )
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
                    $result.Setting | Should -Be 'Disable'
                }
            }

            Context 'Enable NetBios over TCP/IP' {
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName            = 'localhost'
                            InterfaceAlias      = $netAdapter1.NetConnectionID
                            Setting             = 'Enable'
                        }
                    )
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
                    $result.Setting | Should -Be 'Enable'
                }
            }

            Context 'Default NetBios over TCP/IP' {
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName            = 'localhost'
                            InterfaceAlias      = $netAdapter1.NetConnectionID
                            Setting             = 'Default'
                        }
                    )
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
                    $result.Setting | Should -Be 'Default'
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
