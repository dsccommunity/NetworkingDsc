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
        New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA1'
        New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA2'

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

function Invoke-NetBiosIntegrationTest
{
    param (
        [Parameter()]
        [System.String]
        $InterfaceAlias,

        [Parameter()]
        [System.String]
        $Setting = 'Disable'
    )

    $configData = @{
        AllNodes = @(
            @{
                NodeName       = 'localhost'
                InterfaceAlias = $InterfaceAlias
                Setting        = $Setting
            }
        )
    }

    It 'Should compile and apply the MOF without throwing' {
        {
            & "DSC_NetBios_Config" `
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
            $_.ConfigurationName -eq "DSC_NetBios_Config"
        }
        $result.Setting | Should -Be $Setting
    }
}

        Describe "$($script:dscResourceName)_Integration" {
            Context 'When applying to a single network adapter' {
                Context 'When setting NetBios over TCP/IP to Disable' {
                    Invoke-NetBiosIntegrationTest -InterfaceAlias 'NetworkingDscLBA1' -Setting 'Disable'
                }

                Context 'When setting NetBios over TCP/IP to Enable' {
                    Invoke-NetBiosIntegrationTest -InterfaceAlias 'NetworkingDscLBA1' -Setting 'Enable'
                }

                Context 'When setting NetBios over TCP/IP to Default' {
                    Invoke-NetBiosIntegrationTest -InterfaceAlias 'NetworkingDscLBA1' -Setting 'Default'
                }
            }

            Context 'When applying to a all network adapters' {
                Context 'When setting NetBios over TCP/IP to Disable' {
                    Invoke-NetBiosIntegrationTest -InterfaceAlias 'NetworkingDscLBA*' -Setting 'Disable'
                }

                Context 'When setting NetBios over TCP/IP to Enable' {
                    Invoke-NetBiosIntegrationTest -InterfaceAlias 'NetworkingDscLBA*' -Setting 'Enable'
                }

                Context 'When setting NetBios over TCP/IP to Default' {
                    Invoke-NetBiosIntegrationTest -InterfaceAlias 'NetworkingDscLBA*' -Setting 'Default'
                }
            }
        }
    }
}
finally
{
    # Remove Loopback Adapters
    Remove-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA2'
    Remove-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA1'

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
