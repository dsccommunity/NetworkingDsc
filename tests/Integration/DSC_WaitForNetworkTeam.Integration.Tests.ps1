<#
    These tests can not be run in AppVeyor as this will cause the network
    adapter to disconnect and terminate the build.

    They can only be run if two teaming compatible network adapters are
    present on the test machine and the adapters can be safely used in
    a team during the test process.

    Loopback adapters can not be used for NIC teaming and only server OS
    SKU machines will support it.

    To enable this test to be run, add the names of the adapters to use
    for testing into the $script:NetworkTeamMembers array below. E.g.
    $script:NetworkTeamMembers = @('Ethernet','Ethernet 2')
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
    $script:dscResourceFriendlyName = 'WaitForNetworkTeam'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $script:NetworkTeamMembers = @()

    # Check if integration tests can be run
    if (-not (Test-NetworkTeamIntegrationEnvironment -NetworkAdapters $script:NetworkTeamMembers))
    {
        $script:Skip = $true
    }
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'NetworkingDsc'
    $script:dscResourceFriendlyName = 'WaitForNetworkTeam'
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

Describe 'WaitForNetworkTeam Integration Tests' -Skip:$script:Skip {
    BeforeAll {
        $null = New-NetLbfoTeam `
            -Name 'TestTeam' `
            -TeamMembers $script:NetworkTeamMembers `
            -LoadBalancingAlgorithm 'MacAddresses' `
            -TeamingMode 'SwitchIndependent' `
            -Confirm:$false

            $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
            . $configFile
    }

    AfterAll {
        # Remove the team just in case it wasn't removed correctly
        Remove-NetLbfoTeam `
            -Name 'TestTeam' `
            -Confirm:$false `
            -ErrorAction SilentlyContinue
    }

    Describe "$($script:dscResourceName)_Integration" {
        BeforeAll {
            $configurationData = @{
                AllNodes = @(
                    @{
                        NodeName         = 'localhost'
                        Name             = 'TestTeam'
                        RetryIntervalSec = 2
                        RetryCount       = 30
                    }
                )
            }
        }

        Context 'When the network team has been created' {
            AfterEach {
                Wait-ForIdleLcm
            }

            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configurationData

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
                
                $result.Ensure                 | Should -Be $configurationData.AllNodes[0].Ensure
                $result.Name                   | Should -Be $configurationData.AllNodes[0].Name
            }
        }
    }
}
