$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_IPAddress'

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
    Describe 'IPAddress Integration Tests' {
        # Configure loopback adapters
        New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA'
        New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA2'

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

            It 'should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                }
                $current[0].InterfaceAlias | Should -Be $TestIPAddress.InterfaceAlias
                $current[0].AddressFamily  | Should -Be $TestIPAddress.AddressFamily
                $current[0].IPAddress      | Should -Be $TestIPAddress.IPAddress
                $current[1].InterfaceAlias | Should -Be $TestMultipleIPAddress.InterfaceAlias
                $current[1].AddressFamily  | Should -Be $TestMultipleIPAddress.AddressFamily
                $current[1].IPAddress      | Should -Contain $TestMultipleIPAddress.IPAddress[0]
                $current[1].IPAddress      | Should -Contain $TestMultipleIPAddress.IPAddress[1]
            }
        }
    }
}
finally
{
    # Remove Loopback Adapter
    Remove-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA'
    Remove-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA2'

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
