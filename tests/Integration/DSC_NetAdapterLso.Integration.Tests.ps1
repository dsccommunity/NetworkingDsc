$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_NetAdapterLso'

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

<#
    To run these tests a network adapter that has NDIS version of 6 or greater.
    If this is not available then the tests will be skipped.
#>
$script:netAdapter = Get-NetAdapter | Where-Object -FilterScript {
    $_.NdisVersion -ge 6
} | Select-Object -First 1

if (-not $script:netAdapter)
{
    Write-Verbose -Message ('A network adapter with NDIS version of 6 or greater is required to run these tests. Integration tests will be skipped.')
    return
}

# Begin Testing
try
{
    Describe 'NetAdapterLso Integration Tests' {
        $configData = @{
            AllNodes = @(
                @{
                    NodeName = 'localhost'
                    Name     = $script:netAdapter.Name
                    Protocol = 'IPv6'
                    State    = $true
                }
            )
        }

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile -Verbose -ErrorAction Stop

        Describe "$($script:dscResourceName)_Integration" {
            It 'Should compile without throwing' {
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

            It 'Should be able to call Test-DscConfiguration without throwing' {
                { $script:currentState = Test-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should report that DSC is in state' {
                $script:currentState | Should -BeTrue
            }

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                }
                $current.Name     | Should -Be $configData.AllNodes[0].Name
                $current.Protocol | Should -Be $configData.AllNodes[0].Protocol
                $current.State    | Should -Be $configData.AllNodes[0].State
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
