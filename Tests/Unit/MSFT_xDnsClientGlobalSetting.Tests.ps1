$Global:DSCModuleName   = 'xNetworking'
$Global:DSCResourceName = 'MSFT_xDnsClientGlobalSettings'

#region HEADER
# Unit Test Template Version: 1.1.0
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $Global:DSCResourceName {

        # Create the Mock Objects that will be used for running tests
        $NamespaceServerConfiguration = [PSObject]@{
            LdapTimeoutSec               = 45
            SyncIntervalSec              = 5000
            UseFQDN                      = $True
        }
        $NamespaceServerConfigurationSplat = [PSObject]@{
            IsSingleInstance             = 'Yes'
            LdapTimeoutSec               = $NamespaceServerConfiguration.LdapTimeoutSec
            SyncIntervalSec              = $NamespaceServerConfiguration.SyncIntervalSec
            UseFQDN                      = $NamespaceServerConfiguration.UseFQDN
        }

        Describe "$($Global:DSCResourceName)\Get-TargetResource" {

            Context 'Namespace Server Configuration Exists' {

                Mock Get-DFSNServerConfiguration -MockWith { $NamespaceServerConfiguration }

                It 'should return correct namespace server configuration values' {
                    $Result = Get-TargetResource -IsSingleInstance 'Yes'
                    $Result.LdapTimeoutSec            | Should Be $NamespaceServerConfiguration.LdapTimeoutSec
                    $Result.SyncIntervalSec           | Should Be $NamespaceServerConfiguration.SyncIntervalSec
                    $Result.UseFQDN                   | Should Be $NamespaceServerConfiguration.UseFQDN
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-DFSNServerConfiguration -Exactly 1
                }
            }
        }

        Describe "$($Global:DSCResourceName)\Set-TargetResource" {

            Mock Get-DFSNServerConfiguration -MockWith { $NamespaceServerConfiguration }
            Mock Set-DFSNServerConfiguration

            Context 'Namespace Server Configuration all parameters are the same' {
                It 'should not throw error' {
                    {
                        $Splat = $NamespaceServerConfigurationSplat.Clone()
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DFSNServerConfiguration -Exactly 1
                    Assert-MockCalled -commandName Set-DFSNServerConfiguration -Exactly 0
                }
            }

            Context 'Namespace Server Configuration LdapTimeoutSec is different' {
                It 'should not throw error' {
                    {
                        $Splat = $NamespaceServerConfigurationSplat.Clone()
                        $Splat.LdapTimeoutSec = $Splat.LdapTimeoutSec + 1
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DFSNServerConfiguration -Exactly 1
                    Assert-MockCalled -commandName Set-DFSNServerConfiguration -Exactly 1
                }
            }

            Context 'Namespace Server Configuration SyncIntervalSec is different' {
                It 'should not throw error' {
                    {
                        $Splat = $NamespaceServerConfigurationSplat.Clone()
                        $Splat.SyncIntervalSec = $Splat.SyncIntervalSec + 1
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DFSNServerConfiguration -Exactly 1
                    Assert-MockCalled -commandName Set-DFSNServerConfiguration -Exactly 1
                }
            }

            Context 'Namespace Server Configuration UseFQDN is different' {
                It 'should not throw error' {
                    {
                        $Splat = $NamespaceServerConfigurationSplat.Clone()
                        $Splat.UseFQDN = -not $Splat.UseFQDN
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DFSNServerConfiguration -Exactly 1
                    Assert-MockCalled -commandName Set-DFSNServerConfiguration -Exactly 1
                }
            }
        }

        Describe "$($Global:DSCResourceName)\Test-TargetResource" {

            Mock Get-DFSNServerConfiguration -MockWith { $NamespaceServerConfiguration }

            Context 'Namespace Server Configuration all parameters are the same' {
                It 'should return true' {
                    $Splat = $NamespaceServerConfigurationSplat.Clone()
                    Test-TargetResource @Splat | Should Be $True
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DFSNServerConfiguration -Exactly 1
                }
            }

            Context 'Namespace Server Configuration LdapTimeoutSec is different' {
                It 'should return false' {
                    $Splat = $NamespaceServerConfigurationSplat.Clone()
                    $Splat.LdapTimeoutSec = $Splat.LdapTimeoutSec + 1
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DFSNServerConfiguration -Exactly 1
                }
            }

            Context 'Namespace Server Configuration SyncIntervalSec is different' {
                It 'should return false' {
                    $Splat = $NamespaceServerConfigurationSplat.Clone()
                    $Splat.SyncIntervalSec = $Splat.SyncIntervalSec + 1
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DFSNServerConfiguration -Exactly 1
                }
            }

            Context 'Namespace Server Configuration UseFQDN is different' {
                It 'should return false' {
                    $Splat = $NamespaceServerConfigurationSplat.Clone()
                    $Splat.UseFQDN = -not $Splat.UseFQDN
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DFSNServerConfiguration -Exactly 1
                }
            }
        }

        Describe "$($Global:DSCResourceName)\New-TerminatingError" {

            Context 'Create a TestError Exception' {

                It 'should throw an TestError exception' {
                    $errorId = 'TestError'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $errorMessage = 'Test Error Message'
                    $exception = New-Object `
                        -TypeName System.InvalidOperationException `
                        -ArgumentList $errorMessage
                    $errorRecord = New-Object `
                        -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $exception, $errorId, $errorCategory, $null

                    { New-TerminatingError `
                        -ErrorId $errorId `
                        -ErrorMessage $errorMessage `
                        -ErrorCategory $errorCategory } | Should Throw $errorRecord
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
