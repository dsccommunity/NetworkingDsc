$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_HostsFile'

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
    Describe 'HostsFile Integration Tests' {
        Copy-Item -Path "${env:SystemRoot}\System32\Drivers\Etc\Hosts" -Destination "${env:Temp}\Hosts" -Force

        Describe "$($script:dscResourceName)_Integration - Add Single Line" {
            $configData = @{
                AllNodes = @(
                    @{
                        NodeName  = 'localhost'
                        HostName  = 'Host01'
                        IPAddress = '192.168.0.1'
                        Ensure    = 'Present'
                    }
                )
            }

            $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
            . $configFile -Verbose -ErrorAction Stop

            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
                    Start-DscConfiguration `
                        -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $result = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                }
                $result.Ensure                 | Should -Be $configData.AllNodes[0].Ensure
                $result.HostName               | Should -Be $configData.AllNodes[0].HostName
                $result.IPAddress              | Should -Be $configData.AllNodes[0].IPAddress
            }
        }

        Describe "$($script:dscResourceName)_Integration - Add Multiple Line" {
            $configData = @{
                AllNodes = @(
                    @{
                        NodeName  = 'localhost'
                        HostName  = 'Host01'
                        IPAddress = '192.168.0.2'
                        Ensure    = 'Present'
                    }
                )
            }

            $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
            . $configFile -Verbose -ErrorAction Stop

            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
                    Start-DscConfiguration `
                        -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $result = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                }
                $result.Ensure                 | Should -Be $configData.AllNodes[0].Ensure
                $result.HostName               | Should -Be $configData.AllNodes[0].HostName
                $result.IPAddress              | Should -Be $configData.AllNodes[0].IPAddress
            }
        }

        Describe "$($script:dscResourceName)_Integration - Remove Single Line" {
            $configData = @{
                AllNodes = @(
                    @{
                        NodeName  = 'localhost'
                        HostName  = 'Host01'
                        IPAddress = '192.168.0.1'
                        Ensure    = 'Absent'
                    }
                )
            }

            $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
            . $configFile -Verbose -ErrorAction Stop

            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
                    Start-DscConfiguration `
                        -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $result = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                }
                $result.Ensure                 | Should -Be $configData.AllNodes[0].Ensure
                $result.HostName               | Should -Be $configData.AllNodes[0].HostName
                $result.IPAddress              | Should -BeNullOrEmpty
            }
        }
    }
}
finally
{
    # Restore unmodified hosts file
    Copy-Item "${env:Temp}\Hosts" "${env:SystemRoot}\System32\Drivers\Etc\Hosts" -Force

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
