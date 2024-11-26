<#
    To execute integration tests an RDMA compatible adapter is required in the host
    The Microsoft Loopback Adapter is not RDMA compatible so can not be used for
    test automation.

    To run the this test on a machine with a compatible RDMA adapter, set the value of
    the `$script:AdapterName` variable to the name of the adapter to test. The RDMA status
    of the adapter should be restored after test completion.

    Important: this test will disrupt network connectivity to the adapter selected for
    testing, so do not specify an adapter used for connectivity to the test client. This
    is why these tests can not be executed in AppVeyor.
#>

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
    $script:dscResourceFriendlyName = 'NetAdapterRdma'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

    $AdapterName = 'vEthernet (Default Switch)'

    # Check the adapter selected for use in testing is RDMA compatible and preserve state
    $adapterRDMAStatus = Get-NetAdapterRdma -Name $AdapterName -ErrorAction SilentlyContinue

    if (-not $adapterRDMAStatus)
    {
        $script:Skip = $true
    }
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'NetworkingDsc'
    $script:dscResourceFriendlyName = 'NetAdapterRdma'
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

Describe 'NetAdapterName Integration Tests' -Skip:$script:Skip {
    BeforeAll {
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile

        $AdapterName = 'vEthernet (Default Switch)'

        # Check the adapter selected for use in testing is RDMA compatible and preserve state
        $adapterRDMAStatus = Get-NetAdapterRdma -Name $AdapterName -ErrorAction SilentlyContinue

        # Make sure RDMA is disabled on the selected adapter before running tests
        Set-NetAdapterRdma -Name $AdapterName -Enabled $false
    }

    AfterAll {
        Set-NetAdapterRdma -Name $AdapterName -Enabled $adapterRDMAStatus.Enabled
    }

    Describe "$($script:dscResourceName)_Integration" {
        BeforeAll {
            # This is to pass to the Config
            $configData = @{
                AllNodes = @(
                    @{
                        NodeName = 'localhost'
                        Name     = $AdapterName
                        Enabled  = $true
                    }
                )
            }
        }

        AfterAll {
            Set-NetAdapterRdma `
                -Name $configData.AllNodes[0].Name `
                -Enabled $false
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
            $result = Get-DscConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
            }

            $result.Name                   | Should -Be $configData.AllNodes[0].Name
            $result.Enabled                | Should -Be $configData.AllNodes[0].Enabled
        }
    }
}
