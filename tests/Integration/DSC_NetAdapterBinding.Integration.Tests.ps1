$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_NetAdapterBinding'

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
    Describe 'NetAdapterBinding Integration Tests' {
        New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA'

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile -Verbose -ErrorAction Stop

        Describe "$($script:dscResourceName)_Integration" {
            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_Config" -OutputPath $TestDrive

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
                $current.InterfaceAlias | Should -Be $TestDisableIPv4.InterfaceAlias
                $current.ComponentId    | Should -Be $TestDisableIPv4.ComponentId
                $current.State          | Should -Be $TestDisableIPv4.State
            }
        }
    }
}
finally
{
    # Remove Loopback Adapter
    Remove-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA'

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
