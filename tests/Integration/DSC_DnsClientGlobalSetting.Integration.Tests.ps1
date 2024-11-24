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
#     $script:dscResourceFriendlyName = 'DnsClientGlobalSetting'
#     $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
# }

# BeforeAll {
#     # Need to define the variables here which will be used in Pester Run.
#     $script:dscModuleName = 'NetworkingDsc'
#     $script:dscResourceFriendlyName = 'DnsClientGlobalSetting'
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

#     # Clean up
#     Set-DnsClientGlobalSetting `
#         -SuffixSearchList $script:currentDnsClientGlobalSetting.SuffixSearchList `
#         -UseDevolution $script:currentDnsClientGlobalSetting.UseDevolution `
#         -DevolutionLevel $script:currentDnsClientGlobalSetting.DevolutionLevel

#     Restore-TestEnvironment -TestEnvironment $script:testEnvironment
# }

# # Load the parameter List from the data file
# $moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
# $resourceData = Import-LocalizedData `
#     -BaseDirectory (Join-Path -Path $moduleRoot -ChildPath 'Source\DscResources\DSC_DnsClientGlobalSetting') `
#     -FileName 'DSC_DnsClientGlobalSetting.data.psd1'

# $parameterList = $resourceData.ParameterList | Where-Object -Property IntTest -eq $True

# Describe 'DnsClientGlobalSetting Integration Tests' {
#     BeforeAll {
#         # Backup the existing settings
#         $script:currentDnsClientGlobalSetting = Get-DnsClientGlobalSetting

#         # Set the DNS Client Global settings to known values
#         Set-DnsClientGlobalSetting `
#             -SuffixSearchList 'fabrikam.com' `
#             -UseDevolution $False `
#             -DevolutionLevel 4

#         $configData = @{
#             AllNodes = @(
#                 @{
#                     NodeName         = 'localhost'
#                     SuffixSearchList = 'contoso.com'
#                     UseDevolution    = $True
#                     DevolutionLevel  = 2
#                 }
#             )
#         }
#     }

#     Describe "$($script:dscResourceName)_Integration" {
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
#                     -Force
#             } | Should -Not -Throw
#         }

#         It 'Should be able to call Get-DscConfiguration without throwing' {
#             { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
#         }

#         # Get the DNS Client Global Settings details
#         $dnsClientGlobalSettingNew = Get-DnsClientGlobalSetting

#         # Use the Parameters List to perform these tests
#         foreach ($parameter in $parameterList)
#         {
#             $parameterCurrentValue = (Get-Variable -Name 'dnsClientGlobalSettingNew').value.$($parameter.name)
#             $parameterNewValue = (Get-Variable -Name configData).Value.AllNodes[0].$($parameter.Name)

#             It "Should have set the '$parameterName' to '$parameterNewValue'" {
#                 $parameterCurrentValue | Should -Be $parameterNewValue
#             }
#         }
#     }
# }
