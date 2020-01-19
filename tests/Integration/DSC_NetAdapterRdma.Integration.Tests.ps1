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
$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_NetAdapterRdma'
$script:AdapterName = 'vEthernet (Default Switch)'

# Check the adapter selected for use in testing is RDMA compatible and preserve state
$script:adapterRDMAStatus = Get-NetAdapterRdma -Name $script:AdapterName -ErrorAction SilentlyContinue

if (-not $script:adapterRDMAStatus)
{
    Write-Verbose -Message ('The network adapter selected for RDMA integration testing is not RDMA compatible. Integration tests will be skipped.')
    return
}

# Make sure RDMA is disabled on the selected adapter before running tests
Set-NetAdapterRdma -Name $script:AdapterName -Enabled $false

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
    Describe 'NetAdapterName Integration Tests' {
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile -Verbose -ErrorAction Stop

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

        Describe "$($script:dscResourceName)_Integration" {
            AfterAll {
                Set-NetAdapterRdma `
                    -Name $configData.AllNodes[0].Name `
                    -Enabled $false
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
}
finally
{
    Set-NetAdapterRdma -Name $script:AdapterName -Enabled $script:adapterRDMAStatus.Enabled

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
