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
    $script:dscResourceFriendlyName = 'DnsClientNrptRule'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'NetworkingDsc'
    $script:dscResourceFriendlyName = 'DnsClientNrptRule'
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

Describe 'DnsClientNrptRule Integration Tests' {
    BeforeAll {
        $script:dummyRule = [PSObject] @{
            Name        = 'Server'
            Namespace   = '.contoso.com'
            NameServers = ('192.168.1.1')
        }

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile
    }

    AfterAll {
        # Clean up any created rules just in case the integration tests fail
        $null = Remove-DnsClientNrptRule -Name $dummyRule.Name `
            -Force `
            -ErrorAction SilentlyContinue
    }

    Describe "$($script:dscResourceName)_Add_Integration" {
        BeforeAll {
            $configData = @{
                AllNodes = @(
                    @{
                        NodeName    = 'localhost'
                        Name        = $script:dummyRule.Name
                        Namespace   = $script:dummyRule.Namespace
                        NameServers = $script:dummyRule.NameServers
                        Ensure      = 'Present'
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

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
            }

            $current.Name        | Should -Be $configData.AllNodes[0].Name
            $current.Namespace   | Should -Be $configData.AllNodes[0].Namespace
            $current.NameServers | Should -Be $configData.AllNodes[0].NameServers
            $current.Ensure      | Should -Be $configData.AllNodes[0].Ensure
        }

        It 'Should have created the NRPT rule' {
            Get-DnsClientNrptRule -Name $script:dummyRule.Name -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Describe "$($script:dscResourceName)_Remove_Integration" {
        BeforeAll {
            $configData = @{
                AllNodes = @(
                    @{
                        NodeName    = 'localhost'
                        Name        = $script:dummyRule.Name
                        Namespace   = $script:dummyRule.Namespace
                        NameServers = $script:dummyRule.NameServers
                        Ensure      = 'Present'
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

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
            }

            $current.Name        | Should -Be $configData.AllNodes[0].Name
            $current.Namespace   | Should -Be $configData.AllNodes[0].Namespace
            $current.NameServers | Should -Be $configData.AllNodes[0].NameServers
            $current.Ensure      | Should -Be $configData.AllNodes[0].Ensure
        }

        It 'Should have deleted the NRPT rule' {
            Get-DnsClientNrptRule -Name $script:dummyRule.Name | Should -BeNullOrEmpty
        }
    }
}
