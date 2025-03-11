$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_DnsClientNrptRule'

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
    Describe 'NRPT Rule Integration Tests' {
        $script:dummyRule = [PSObject] @{
            Name        = 'Server'
            Namespace   = '.contoso.com'
            NameServers = ('192.168.1.1')
        }

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile -Verbose -ErrorAction Stop

        Describe "$($script:dscResourceName)_Add_Integration" {
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
            $configData = @{
                AllNodes = @(
                    @{
                        NodeName    = 'localhost'
                        Name        = $script:dummyRule.Name
                        Namespace   = $script:dummyRule.Namespace
                        NameServers = $script:dummyRule.NameServers
                        Ensure      = 'Absent'
                    }
                )
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
}
finally
{
    # Clean up any created rules just in case the integration tests fail
    $null = Remove-DnsClientNrptRule $script:dummyRule.Name `
        -Force`
        -ErrorAction SilentlyContinue

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
