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
    $script:dscResourceFriendlyName = 'IPAddress'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'NetworkingDsc'
    $script:dscResourceFriendlyName = 'IPAddress'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

AfterAll {
    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Describe "$($script:dscResourceName)_Integration" {
    BeforeAll {
        New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA1'
        New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA2'
    }

    AfterAll {
        Remove-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA1'
        Remove-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA2'
    }

    Context 'When a single IP address is specified' {
        BeforeAll {
            # This is to pass to the Config
            $configData = @{
                AllNodes = @(
                    @{
                        NodeName       = 'localhost'
                        InterfaceAlias = 'NetworkingDscLBA1'
                        AddressFamily  = 'IPv4'
                        IPAddress      = '10.11.12.13/16'
                    }
                )
            }
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

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
            }
            $current[0].InterfaceAlias | Should -Be $configData.AllNodes[0].InterfaceAlias
            $current[0].AddressFamily | Should -Be $configData.AllNodes[0].AddressFamily
            $current[0].IPAddress | Should -Be $configData.AllNodes[0].IPAddress
        }
    }
}

Context 'When a two IP addresses are specified' {
    BeforeAll {
        # This is to pass to the Config
        $configData = @{
            AllNodes = @(
                @{
                    NodeName       = 'localhost'
                    InterfaceAlias = 'NetworkingDscLBA2'
                    AddressFamily  = 'IPv4'
                    IPAddress      = @('10.12.13.14/16', '10.13.14.16/32')
                }
            )
        }
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

    It 'should be able to call Get-DscConfiguration without throwing' {
        { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
    }

    It 'Should have set the resource and all the parameters should match' {
        $current = Get-DscConfiguration | Where-Object -FilterScript {
            $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
        }
        $current[0].InterfaceAlias | Should -Be $configData.AllNodes[0].InterfaceAlias
        $current[0].AddressFamily | Should -Be $configData.AllNodes[0].AddressFamily
        $current[0].IPAddress | Should -Contain $configData.AllNodes[0].IPAddress[0]
        $current[0].IPAddress | Should -Contain $configData.AllNodes[0].IPAddress[1]
    }
}
