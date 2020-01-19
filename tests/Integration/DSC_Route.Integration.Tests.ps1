$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_Route'

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
    Describe 'Route Integration Tests' {
        $script:interfaceAlias = (Get-NetAdapter -Physical | Select-Object -First 1).Name

        $script:dummyRoute = [PSObject] @{
            InterfaceAlias    = $script:interfaceAlias
            AddressFamily     = 'IPv4'
            DestinationPrefix = '11.0.0.0/8'
            NextHop           = '11.0.1.0'
            RouteMetric       = 200
        }

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile -Verbose -ErrorAction Stop

        Describe "$($script:dscResourceName)_Add_Integration" {
            $configData = @{
                AllNodes = @(
                    @{
                        NodeName          = 'localhost'
                        InterfaceAlias    = $script:interfaceAlias
                        AddressFamily     = $script:dummyRoute.AddressFamily
                        DestinationPrefix = $script:dummyRoute.DestinationPrefix
                        NextHop           = $script:dummyRoute.NextHop
                        Ensure            = 'Present'
                        RouteMetric       = $script:dummyRoute.RouteMetric
                        Publish           = 'No'
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

                $current.InterfaceAlias    | Should -Be $configData.AllNodes[0].InterfaceAlias
                $current.AddressFamily     | Should -Be $configData.AllNodes[0].AddressFamily
                $current.DestinationPrefix | Should -Be $configData.AllNodes[0].DestinationPrefix
                $current.NextHop           | Should -Be $configData.AllNodes[0].NextHop
                $current.Ensure            | Should -Be $configData.AllNodes[0].Ensure
                $current.RouteMetric       | Should -Be $configData.AllNodes[0].RouteMetric
                $current.Publish           | Should -Be $configData.AllNodes[0].Publish
            }

            It 'Should have created the route' {
                Get-NetRoute @dummyRoute -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }

        Describe "$($script:dscResourceName)_Remove_Integration" {
            $configData = @{
                AllNodes = @(
                    @{
                        NodeName          = 'localhost'
                        InterfaceAlias    = $script:interfaceAlias
                        AddressFamily     = $script:dummyRoute.AddressFamily
                        DestinationPrefix = $script:dummyRoute.DestinationPrefix
                        NextHop           = $script:dummyRoute.NextHop
                        Ensure            = 'Absent'
                        RouteMetric       = $script:dummyRoute.RouteMetric
                        Publish           = 'No'
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

                $current.InterfaceAlias    | Should -Be $configData.AllNodes[0].InterfaceAlias
                $current.AddressFamily     | Should -Be $configData.AllNodes[0].AddressFamily
                $current.DestinationPrefix | Should -Be $configData.AllNodes[0].DestinationPrefix
                $current.NextHop           | Should -Be $configData.AllNodes[0].NextHop
                $current.Ensure            | Should -Be $configData.AllNodes[0].Ensure
            }

            It 'Should have deleted the route' {
                Get-NetRoute @dummyRoute -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            }
        }
    }
}
finally
{
    # Clean up any created routes just in case the integration tests fail
    $null = Remove-NetRoute @dummyRoute `
        -Confirm:$false `
        -ErrorAction SilentlyContinue

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
