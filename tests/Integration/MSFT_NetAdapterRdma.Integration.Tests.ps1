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
$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_NetAdapterRdma'
$script:AdapterName = 'vEthernet (Default Switch)'

# Check the adapter selected for use in testing is RDMA compatible and preserve state
$adapterRDMAStatus = Get-NetAdapterRdma -Name $script:AdapterName -ErrorAction SilentlyContinue
if (-not $adapterRDMAStatus)
{
    Write-Verbose -Message ('The network adapter selected for RDMA integration testing is not RDMA compatible. Integration tests will be skipped.')
    return
}

# Make sure RDMA is disabled on the selected adapter before running tests
Set-NetAdapterRdma -Name $script:AdapterName -Enabled $false

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
    #region Integration Tests
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    # This is to pass to the Config
    $configData = @{
        AllNodes = @(
            @{
                NodeName = 'localhost'
                Name     = $script:AdapterName
                Enabled  = $true
            }
        )
    }

    Describe "$($script:DSCResourceName)_Integration" {
        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:DSCResourceName)_Config" `
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
                $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
            }
            $result.Name                   | Should -Be $configData.AllNodes[0].Name
            $result.Enabled                | Should -Be $configData.AllNodes[0].Enabled
        }

        Set-NetAdapterRdma `
            -Name $configData.AllNodes[0].Name `
            -Enabled $false
    }
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    Set-NetAdapterRdma -Name $script:AdapterName -Enabled $adapterRDMAStatus.Enabled
    #endregion
}
