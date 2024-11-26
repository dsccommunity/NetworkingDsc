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
#     $script:dscResourceFriendlyName = 'NetAdapterLso'
#     $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

#     <#
#     To run these tests a network adapter that has NDIS version of 6 or greater.
#     If this is not available then the tests will be skipped.
#     #>
#     $script:netAdapter = Get-NetAdapter | Where-Object -FilterScript {
#         $_.NdisVersion -ge 6
#     } | Select-Object -First 1

#     if (-not $script:netAdapter)
#     {
#         $script:skip = $true
#     }
# }

# BeforeAll {
#     # Need to define the variables here which will be used in Pester Run.
#     $script:dscModuleName = 'NetworkingDsc'
#     $script:dscResourceFriendlyName = 'NetAdapterLso'
#     $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

#     $script:testEnvironment = Initialize-TestEnvironment `
#         -DSCModuleName $script:dscModuleName `
#         -DSCResourceName $script:dscResourceName `
#         -ResourceType 'Mof' `
#         -TestType 'Integration'

#     $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
#     . $configFile

#     Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

#     $script:netAdapter = Get-NetAdapter | Where-Object -FilterScript {
#         $_.NdisVersion -ge 6
#     } | Select-Object -First 1
# }

# AfterAll {
#     # Remove module common test helper.
#     Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

#     Restore-TestEnvironment -TestEnvironment $script:testEnvironment
# }

# Describe 'NetAdapterLso Integration Tests' {
#     BeforeAll {
#         $configData = @{
#             AllNodes = @(
#                 @{
#                     NodeName = 'localhost'
#                     Name     = $script:netAdapter.Name
#                     Protocol = 'IPv6'
#                     State    = $true
#                 }
#             )
#         }
#     }

#     Describe "$($script:dscResourceName)_Integration" {
#         It 'Should compile without throwing' {
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

#         It 'Should be able to call Test-DscConfiguration without throwing' {
#             { $script:currentState = Test-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
#         }

#         It 'Should report that DSC is in state' {
#             $script:currentState | Should -BeTrue
#         }

#         It 'Should have set the resource and all the parameters should match' {
#             $current = Get-DscConfiguration | Where-Object -FilterScript {
#                 $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
#             }
#             $current.Name     | Should -Be $configData.AllNodes[0].Name
#             $current.Protocol | Should -Be $configData.AllNodes[0].Protocol
#             $current.State    | Should -Be $configData.AllNodes[0].State
#         }
#     }
# }
