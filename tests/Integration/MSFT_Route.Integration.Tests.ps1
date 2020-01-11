$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_Route'

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
    $interfaceAlias = (Get-NetAdapter -Physical | Select-Object -First 1).Name

    $dummyRoute = [PSObject] @{
        InterfaceAlias    = $interfaceAlias
        AddressFamily     = 'IPv4'
        DestinationPrefix = '11.0.0.0/8'
        NextHop           = '11.0.1.0'
        RouteMetric       = 200
    }

    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    Describe "$($script:DSCResourceName)_Add_Integration" {
        $configData = @{
            AllNodes = @(
                @{
                    NodeName          = 'localhost'
                    InterfaceAlias    = $interfaceAlias
                    AddressFamily     = $dummyRoute.AddressFamily
                    DestinationPrefix = $dummyRoute.DestinationPrefix
                    NextHop           = $dummyRoute.NextHop
                    Ensure            = 'Present'
                    RouteMetric       = $dummyRoute.RouteMetric
                    Publish           = 'No'
                }
            )
        }

        #region DEFAULT TESTS
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
        #endregion

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
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

    Describe "$($script:DSCResourceName)_Remove_Integration" {
        $configData = @{
            AllNodes = @(
                @{
                    NodeName          = 'localhost'
                    InterfaceAlias    = $interfaceAlias
                    AddressFamily     = $dummyRoute.AddressFamily
                    DestinationPrefix = $dummyRoute.DestinationPrefix
                    NextHop           = $dummyRoute.NextHop
                    Ensure            = 'Absent'
                    RouteMetric       = $dummyRoute.RouteMetric
                    Publish           = 'No'
                }
            )
        }

        #region DEFAULT TESTS
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
        #endregion

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
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
    #endregion
}
finally
{
    # Clean up any created routes just in case the integration tests fail
    $null = Remove-NetRoute @dummyRoute `
        -Confirm:$false `
        -ErrorAction SilentlyContinue

    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
