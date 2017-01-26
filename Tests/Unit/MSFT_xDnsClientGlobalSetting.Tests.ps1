$script:DSCModuleName   = 'xNetworking'
$script:DSCResourceName = 'MSFT_xDnsClientGlobalSetting'

#region HEADER
# Unit Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xNetworking'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $script:DSCResourceName {

        # Create the Mock Objects that will be used for running tests
        $DnsClientGlobalSettings = [PSObject]@{
            SuffixSearchList             = 'contoso.com'
            DevolutionLevel              = 1
            UseDevolution                = $True
        }
        $DnsClientGlobalSettingsSplat = [PSObject]@{
            IsSingleInstance             = 'Yes'
            SuffixSearchList             = $DnsClientGlobalSettings.SuffixSearchList
            DevolutionLevel              = $DnsClientGlobalSettings.DevolutionLevel
            UseDevolution                = $DnsClientGlobalSettings.UseDevolution
        }

        Describe "MSFT_xDnsClientGlobalSetting\Get-TargetResource" {

            Context 'DNS Client Global Settings Exists' {

                Mock Get-DnsClientGlobalSetting -MockWith { $DnsClientGlobalSettings }

                It 'should return correct DNS Client Global Settings values' {
                    $getTargetResourceParameters = Get-TargetResource -IsSingleInstance 'Yes'
                    $getTargetResourceParameters.SuffixSearchList | Should Be $DnsClientGlobalSettings.SuffixSearchList
                    $getTargetResourceParameters.DevolutionLevel  | Should Be $DnsClientGlobalSettings.DevolutionLevel
                    $getTargetResourceParameters.UseDevolution    | Should Be $DnsClientGlobalSettings.UseDevolution
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-DnsClientGlobalSetting -Exactly 1
                }
            }
        }

        Describe "MSFT_xDnsClientGlobalSetting\Set-TargetResource" {

            Mock Get-DnsClientGlobalSetting -MockWith { $DnsClientGlobalSettings }
            Mock Set-DnsClientGlobalSetting

            Context 'DNS Client Global Settings all parameters are the same' {
                It 'should not throw error' {
                    {
                        $setTargetResourceParameters = $DnsClientGlobalSettingsSplat.Clone()
                        Set-TargetResource @setTargetResourceParameters
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly 1
                    Assert-MockCalled -commandName Set-DnsClientGlobalSetting -Exactly 0
                }
            }

            Context 'DNS Client Global Settings SuffixSearchList is different' {
                It 'should not throw error' {
                    {
                        $setTargetResourceParameters = $DnsClientGlobalSettingsSplat.Clone()
                        $setTargetResourceParameters.SuffixSearchList = 'fabrikam.com'
                        Set-TargetResource @setTargetResourceParameters
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly 1
                    Assert-MockCalled -commandName Set-DnsClientGlobalSetting -Exactly 1
                }
            }

            Context 'DNS Client Global Settings SuffixSearchList Array is different' {
                $suffixSearchListArray = @('fabrikam.com', 'fourthcoffee.com')

                Mock -CommandName Set-DnsClientGlobalSetting -ParameterFilter {
                    (Compare-Object -ReferenceObject $suffixSearchList -DifferenceObject $suffixSearchListArray -SyncWindow 0).Length -eq 0
                } -MockWith {
                    return $null
                }
                Mock -CommandName Set-DnsClientGlobalSetting -MockWith {
                    throw
                }

                It 'should not throw error' {
                    {
                        $setTargetResourceParameters = $DnsClientGlobalSettingsSplat.Clone()
                        $setTargetResourceParameters.SuffixSearchList = $suffixSearchListArray
                        Set-TargetResource @setTargetResourceParameters
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly 1
                    Assert-MockCalled -commandName Set-DnsClientGlobalSetting -ParameterFilter {
                        (Compare-Object -ReferenceObject $suffixSearchList -DifferenceObject $suffixSearchListArray -SyncWindow 0).Length -eq 0
                    } -Exactly 1
                }
            }

            Context 'DNS Client Global Settings DevolutionLevel is different' {
                It 'should not throw error' {
                    {
                        $setTargetResourceParameters = $DnsClientGlobalSettingsSplat.Clone()
                        $setTargetResourceParameters.DevolutionLevel = $setTargetResourceParameters.DevolutionLevel + 1
                        Set-TargetResource @setTargetResourceParameters
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly 1
                    Assert-MockCalled -commandName Set-DnsClientGlobalSetting -Exactly 1
                }
            }

            Context 'DNS Client Global Settings UseDevolution is different' {
                It 'should not throw error' {
                    {
                        $setTargetResourceParameters = $DnsClientGlobalSettingsSplat.Clone()
                        $setTargetResourceParameters.UseDevolution = -not $setTargetResourceParameters.UseDevolution
                        Set-TargetResource @setTargetResourceParameters
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly 1
                    Assert-MockCalled -commandName Set-DnsClientGlobalSetting -Exactly 1
                }
            }
        }

        Describe "MSFT_xDnsClientGlobalSetting\Test-TargetResource" {

            Mock Get-DnsClientGlobalSetting -MockWith { $DnsClientGlobalSettings }

            Context 'DNS Client Global Settings all parameters are the same' {
                It 'should return true' {
                    $testTargetResourceParameters = $DnsClientGlobalSettingsSplat.Clone()
                    Test-TargetResource @testTargetResourceParameters | Should Be $True
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly 1
                }
            }

            Context 'DNS Client Global Settings SuffixSearchList is different' {
                It 'should return false' {
                    $testTargetResourceParameters = $DnsClientGlobalSettingsSplat.Clone()
                    $testTargetResourceParameters.SuffixSearchList = 'fabrikam.com'
                    Test-TargetResource @testTargetResourceParameters | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly 1
                }
            }

            Context 'DNS Client Global Settings SuffixSearchList Array is different' {
                $suffixSearchListArray = @('fabrikam.com', 'fourthcoffee.com')

                Mock -CommandName Get-DnsClientGlobalSetting -ParameterFilter {
                    (Compare-Object -ReferenceObject $suffixSearchList -DifferenceObject $suffixSearchListArray -SyncWindow 0).Length -eq 0
                } -MockWith {
                    $DnsClientGlobalSettings
                }
                Mock -CommandName Get-DnsClientGlobalSetting -MockWith {
                    throw
                }

                It 'should return false' {
                    $testTargetResourceParameters = $DnsClientGlobalSettingsSplat.Clone()
                    $testTargetResourceParameters.SuffixSearchList = $suffixSearchListArray
                    Test-TargetResource @testTargetResourceParameters | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly 1
                }
            }

            Context 'DNS Client Global Settings SuffixSearchList Array Order is same' {
                $suffixSearchListArray = @('fabrikam.com', 'fourthcoffee.com')
                $DnsClientGlobalSettings = [PSObject]@{
                    SuffixSearchList             = @('fabrikam.com', 'fourthcoffee.com')
                    DevolutionLevel              = 1
                    UseDevolution                = $True
                }

                Mock -CommandName Get-DnsClientGlobalSetting -ParameterFilter {
                    (Compare-Object -ReferenceObject $suffixSearchList -DifferenceObject $suffixSearchListArray -SyncWindow 0).Length -eq 0
                } -MockWith {
                    $DnsClientGlobalSettings
                }
                Mock -CommandName Get-DnsClientGlobalSetting -MockWith {
                    throw
                }

                It 'should return true' {
                    $testTargetResourceParameters = $DnsClientGlobalSettingsSplat.Clone()
                    $testTargetResourceParameters.SuffixSearchList = $suffixSearchListArray
                    Test-TargetResource @testTargetResourceParameters | Should Be $True
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly 1
                }
            }

            Context 'DNS Client Global Settings SuffixSearchList Array Order is different' {
                $suffixSearchListArray = @('fourthcoffee.com', 'fabrikam.com')
                $DnsClientGlobalSettings = [PSObject]@{
                    SuffixSearchList             = @('fabrikam.com', 'fourthcoffee.com')
                    DevolutionLevel              = 1
                    UseDevolution                = $True
                }

                Mock -CommandName Get-DnsClientGlobalSetting -ParameterFilter {
                    (Compare-Object -ReferenceObject $suffixSearchList -DifferenceObject $suffixSearchListArray -SyncWindow 0).Length -eq 0
                } -MockWith {
                    $DnsClientGlobalSettings
                }
                Mock -CommandName Get-DnsClientGlobalSetting -MockWith {
                    throw
                }

                It 'should return false' {
                    $testTargetResourceParameters = $DnsClientGlobalSettingsSplat.Clone()
                    $testTargetResourceParameters.SuffixSearchList = $suffixSearchListArray
                    Test-TargetResource @testTargetResourceParameters | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly 1
                }
            }

            Context 'DNS Client Global Settings DevolutionLevel is different' {
                It 'should return false' {
                    $testTargetResourceParameters = $DnsClientGlobalSettingsSplat.Clone()
                    $testTargetResourceParameters.DevolutionLevel = $testTargetResourceParameters.DevolutionLevel + 1
                    Test-TargetResource @testTargetResourceParameters | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly 1
                }
            }

            Context 'DNS Client Global Settings UseDevolution is different' {
                It 'should return false' {
                    $testTargetResourceParameters = $DnsClientGlobalSettingsSplat.Clone()
                    $testTargetResourceParameters.UseDevolution = -not $testTargetResourceParameters.UseDevolution
                    Test-TargetResource @testTargetResourceParameters | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly 1
                }
            }
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
