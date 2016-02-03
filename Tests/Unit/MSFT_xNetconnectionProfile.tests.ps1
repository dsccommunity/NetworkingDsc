$Global:DSCModuleName      = 'xNetworking'
$Global:DSCResourceName    = 'MSFT_xNetConnectionProfile'

#region HEADER
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}
else
{
    & git @('-C',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit 
#endregion

# Begin Testing
try
{

    #region Pester Tests

    InModuleScope $Global:DSCResourceName {
            
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
            Mock Get-NetConnectionProfile {
                return @{
                    InterfaceAlias   = 'InterfaceAlias'
                    NetworkCategory  = 'Wired'
                    IPv4Connectivity = 'IPv4'
                    IPv6Connectivity = 'IPv6'
                }
            }
            $expected = Get-NetConnectionProfile | select -first 1
            $result = Get-TargetResource -InterfaceAlias $expected.InterfaceAlias
    
            It 'Should return the correct values' {
                $expected.InterfaceAlias   | Should Be $result.InterfaceAlias
                $expected.NetworkCategory  | Should Be $result.NetworkCategory
                $expected.IPv4Connectivity | Should Be $result.IPv4Connectivity
                $expected.IPv6Connectivity | Should Be $result.IPv6Connectivity
            }
        }
    
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            $Splat = @{
                InterfaceAlias   = 'Test'
                NetworkCategory  = 'Private'
                IPv4Connectivity = 'Internet'
                IPv6Connectivity = 'Disconnected'
            }
    
            Context 'IPv4Connectivity is incorrect' {
                $incorrect = $Splat.Clone()
                $incorrect.IPv4Connectivity = 'Disconnected'
                Mock Get-TargetResource {
                    return $incorrect
                }
    
                It 'should return false' {
                    Test-TargetResource @Splat | should be $false
                }
            }
    
            Context 'IPv6Connectivity is incorrect' {
                $incorrect = $Splat.Clone()
                $incorrect.IPv6Connectivity = 'Internet'
                Mock Get-TargetResource {
                    return $incorrect
                }
    
                It 'should return false' {
                    Test-TargetResource @Splat | should be $false
                }
            }
    
            Context 'NetworkCategory is incorrect' {
                $incorrect = $Splat.Clone()
                $incorrect.NetworkCategory = 'Public'
                Mock Get-TargetResource {
                    return $incorrect
                }
    
                It 'should return false' {
                    Test-TargetResource @Splat | should be $false
                }
            }
        }
    
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            It 'Should do call all the mocks' {
                $Splat = @{
                    InterfaceAlias   = 'Test'
                    NetworkCategory  = 'Private'
                    IPv4Connectivity = 'Internet'
                    IPv6Connectivity = 'Disconnected'
                }
    
                Mock Set-NetConnectionProfile {}
    
                Set-TargetResource @Splat
    
                Assert-MockCalled Set-NetConnectionProfile
            }
        }
    } #end InModuleScope $DSCResourceName
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
