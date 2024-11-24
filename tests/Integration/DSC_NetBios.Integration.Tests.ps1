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

    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    # Configure Loopback Adapters
    New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA1'
    New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA2'
}

AfterAll {
    # Remove Loopback Adapters
    Remove-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA2'
    Remove-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA1'

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
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                & 'DSC_NetBios_Config' `
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
                $_.ConfigurationName -eq 'DSC_NetBios_Config'
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
