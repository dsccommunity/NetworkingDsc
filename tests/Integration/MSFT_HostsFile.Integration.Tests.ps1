$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_HostsFile'

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
    Copy-Item -Path "${env:SystemRoot}\System32\Drivers\Etc\Hosts" -Destination "${env:Temp}\Hosts" -Force

    #region Integration Tests
    Describe "$($script:DSCResourceName)_Integration - Add Single Line" {
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

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
        . $configFile -Verbose -ErrorAction Stop

        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:DSCResourceName)_Config" `
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
                $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
            }
            $result.Ensure                 | Should -Be $configData.AllNodes[0].Ensure
            $result.HostName               | Should -Be $configData.AllNodes[0].HostName
            $result.IPAddress              | Should -Be $configData.AllNodes[0].IPAddress
        }
    }

    Describe "$($script:DSCResourceName)_Integration - Add Multiple Line" {
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

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
        . $configFile -Verbose -ErrorAction Stop

        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:DSCResourceName)_Config" `
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
                $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
            }
            $result.Ensure                 | Should -Be $configData.AllNodes[0].Ensure
            $result.HostName               | Should -Be $configData.AllNodes[0].HostName
            $result.IPAddress              | Should -Be $configData.AllNodes[0].IPAddress
        }
    }

    Describe "$($script:DSCResourceName)_Integration - Remove Single Line" {
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

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
        . $configFile -Verbose -ErrorAction Stop

        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:DSCResourceName)_Config" `
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
                $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
            }
            $result.Ensure                 | Should -Be $configData.AllNodes[0].Ensure
            $result.HostName               | Should -Be $configData.AllNodes[0].HostName
            $result.IPAddress              | Should -BeNullOrEmpty
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    #Restore unmodified hosts file
    Copy-Item "${env:Temp}\Hosts" "${env:SystemRoot}\System32\Drivers\Etc\Hosts" -Force
    #endregion
}
