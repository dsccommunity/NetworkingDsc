# [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
# param ()

# BeforeDiscovery {
#     try
#     {
#         if (-not (Get-Module -Name 'DscResource.Test'))
#         {
#             # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
#             if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
#             {
#                 # Redirect all streams to $null, except the error stream (stream 2)
#                 & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
#             }

#             # If the dependencies has not been resolved, this will throw an error.
#             Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
#         }
#     }
#     catch [System.IO.FileNotFoundException]
#     {
#         throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
#     }

#     <#
#         Need to define that variables here to be used in the Pester Discover to
#         build the ForEach-blocks.
#     #>
#     $script:dscResourceFriendlyName = 'Route'
#     $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
# }

# BeforeAll {
#     # Need to define the variables here which will be used in Pester Run.
#     $script:dscModuleName = 'NetworkingDsc'
#     $script:dscResourceFriendlyName = 'Route'
#     $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

#     $script:testEnvironment = Initialize-TestEnvironment `
#         -DSCModuleName $script:dscModuleName `
#         -DSCResourceName $script:dscResourceName `
#         -ResourceType 'Mof' `
#         -TestType 'Integration'

#     $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
#     . $configFile

#     Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
# }

# AfterAll {
#     # Remove module common test helper.
#     Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

#     # Clean up any created routes just in case the integration tests fail
#     $null = Remove-NetRoute @dummyRoute `
#         -Confirm:$false `
#         -ErrorAction SilentlyContinue

#     Restore-TestEnvironment -TestEnvironment $script:testEnvironment
# }

# Describe 'Route Integration Tests' {
#     BeforeAll {
#         $script:interfaceAlias = (Get-NetAdapter -Physical | Select-Object -First 1).Name

#         $script:dummyRoute = [PSObject] @{
#             InterfaceAlias    = $script:interfaceAlias
#             AddressFamily     = 'IPv4'
#             DestinationPrefix = '11.0.0.0/8'
#             NextHop           = '11.0.1.0'
#             RouteMetric       = 200
#         }
#     }

#     Describe "$($script:dscResourceName)_Add_Integration" {
#         BeforeAll {
#             $configData = @{
#                 AllNodes = @(
#                     @{
#                         NodeName          = 'localhost'
#                         InterfaceAlias    = $script:interfaceAlias
#                         AddressFamily     = $script:dummyRoute.AddressFamily
#                         DestinationPrefix = $script:dummyRoute.DestinationPrefix
#                         NextHop           = $script:dummyRoute.NextHop
#                         Ensure            = 'Present'
#                         RouteMetric       = $script:dummyRoute.RouteMetric
#                         Publish           = 'No'
#                     }
#                 )
#             }
#         }

#         It 'Should compile and apply the MOF without throwing' {
#             {
#                 & "$($script:dscResourceName)_Config" `
#                     -OutputPath $TestDrive `
#                     -ConfigurationData $configData

#                 Start-DscConfiguration `
#                     -Path $TestDrive `
#                     -ComputerName localhost `
#                     -Wait `
#                     -Verbose `
#                     -Force `
#                     -ErrorAction Stop
#             } | Should -Not -Throw
#         }

#         It 'Should be able to call Get-DscConfiguration without throwing' {
#             { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
#         }

#         It 'Should have set the resource and all the parameters should match' {
#             $current = Get-DscConfiguration | Where-Object -FilterScript {
#                 $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
#             }

#             $current.InterfaceAlias    | Should -Be $configData.AllNodes[0].InterfaceAlias
#             $current.AddressFamily     | Should -Be $configData.AllNodes[0].AddressFamily
#             $current.DestinationPrefix | Should -Be $configData.AllNodes[0].DestinationPrefix
#             $current.NextHop           | Should -Be $configData.AllNodes[0].NextHop
#             $current.Ensure            | Should -Be $configData.AllNodes[0].Ensure
#             $current.RouteMetric       | Should -Be $configData.AllNodes[0].RouteMetric
#             $current.Publish           | Should -Be $configData.AllNodes[0].Publish
#         }

#         It 'Should have created the route' {
#             Get-NetRoute @dummyRoute -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
#         }
#     }

#     Describe "$($script:dscResourceName)_Remove_Integration" {
#         BeforeAll {
#             $configData = @{
#                 AllNodes = @(
#                     @{
#                         NodeName          = 'localhost'
#                         InterfaceAlias    = $script:interfaceAlias
#                         AddressFamily     = $script:dummyRoute.AddressFamily
#                         DestinationPrefix = $script:dummyRoute.DestinationPrefix
#                         NextHop           = $script:dummyRoute.NextHop
#                         Ensure            = 'Absent'
#                         RouteMetric       = $script:dummyRoute.RouteMetric
#                         Publish           = 'No'
#                     }
#                 )
#             }
#         }

#         It 'Should compile and apply the MOF without throwing' {
#             {
#                 & "$($script:dscResourceName)_Config" `
#                     -OutputPath $TestDrive `
#                     -ConfigurationData $configData

#                 Start-DscConfiguration `
#                     -Path $TestDrive `
#                     -ComputerName localhost `
#                     -Wait `
#                     -Verbose `
#                     -Force `
#                     -ErrorAction Stop
#             } | Should -Not -Throw
#         }

#         It 'Should be able to call Get-DscConfiguration without throwing' {
#             { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
#         }

#         It 'Should have set the resource and all the parameters should match' {
#             $current = Get-DscConfiguration | Where-Object -FilterScript {
#                 $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
#             }

#             $current.InterfaceAlias    | Should -Be $configData.AllNodes[0].InterfaceAlias
#             $current.AddressFamily     | Should -Be $configData.AllNodes[0].AddressFamily
#             $current.DestinationPrefix | Should -Be $configData.AllNodes[0].DestinationPrefix
#             $current.NextHop           | Should -Be $configData.AllNodes[0].NextHop
#             $current.Ensure            | Should -Be $configData.AllNodes[0].Ensure
#         }

#         It 'Should have deleted the route' {
#             Get-NetRoute @dummyRoute -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
#         }
#     }
# }
