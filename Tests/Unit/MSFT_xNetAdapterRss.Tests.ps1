$script:DSCModuleName   = 'xNetworking'
$script:DSCResourceName = 'MSFT_xNetAdapterRss'

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


        $TestRssEnabled = @{
            Name     = 'Ethernet'
            State    = $true
        }

        $TestRssDisabled = @{
            Name     = 'Ethernet'
            State    = $false
        }

        $TestAdapterNotFound = @{
            Name     = 'Eth'
            State    = $true
        }


            Context 'Adapter exist and Rss is enabled' {
                Mock -CommandName Get-NetAdapterRss -MockWith { 
                    @{ RssEnabled = $TestRssEnabled.State }
                }

                It 'Should return the Rss state' {
                    $result = Get-TargetResource @TestRssEnabled
                    $result.State | Should Be $TestRssEnabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRss -Exactly 1
                }
            }

            Context 'Adapter exist and Rss is disabled' {
                Mock -CommandName Get-NetAdapterRss -MockWith { 
                    @{ RssEnabled = $TestRssDisabled.State }
                }

                It 'Should return the Rss state' {
                    $result = Get-TargetResource @TestRssDisabled
                    $result.State | Should Be $TestRssDisabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRss -Exactly 1
                }
            }

            Context 'Adapter does not exist' {
                Mock -CommandName Get-NetAdapterRss -MockWith { throw 'Network adapter not found' }

                It 'Should throw an exception' {
                    { Get-TargetResource @TestAdapterNotFound } | Should throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRss -Exactly 1 
                }
            }
        }

        Describe "$($script:DSCResourceName)\Set-TargetResource" {

            # RSS
            Context 'Adapter exist, Rss is enabled, no action required' {
                Mock -CommandName Get-NetAdapterRss -MockWith { 
                    @{ RssEnabled = $TestRssEnabled.State }
                }
                Mock -CommandName Set-NetAdapterRss

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestRssEnabled } | Should Not Throw
                }
                
                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRss -Exactly 1
                    Assert-MockCalled -CommandName Set-NetAdapterRss -Exactly 0
                }
            }

            Context 'Adapter exist, Rss is enabled, should be disabled' {
                Mock -CommandName Get-NetAdapterRss -MockWith { 
                    @{ RssEnabled = $TestRssEnabled.State }
                }
                Mock -CommandName Set-NetAdapterRss

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestRssDisabled } | Should Not Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRss -Exactly 1
                    Assert-MockCalled -CommandName Set-NetAdapterRss -Exactly 1
                }
            }

            Context 'Adapter exist, Rss is disabled, no action required' {
                Mock -CommandName Get-NetAdapterRss -MockWith { 
                    @{ RssEnabled = $TestRssDisabled.State }
                }
                Mock -CommandName Set-NetAdapterRss

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestRssDisabled } | Should Not Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRss -Exactly 1
                    Assert-MockCalled -CommandName Set-NetAdapterRss -Exactly 0
                }
            }

            Context 'Adapter exist, Rss is disabled, should be enabled.' {
                Mock -CommandName Get-NetAdapterRss -MockWith { 
                    @{ RssEnabled = $TestRssDisabled.State }
                }
                Mock -CommandName Set-NetAdapterRss

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestRssEnabled } | Should Not Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRss -Exactly 1
                    Assert-MockCalled -CommandName Set-NetAdapterRss -Exactly 1
                }
            }

            # Adapter
            Context 'Adapter does not exist' {
                Mock -CommandName Get-NetAdapterRss -MockWith { throw 'Network adapter not found' }

                It 'Should throw an exception' {
                    { Set-TargetResource @TestAdapterNotFound } | Should throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRss -Exactly 1 
                }
            }

        }

        Describe "$($script:DSCResourceName)\Test-TargetResource" {

            # RSS
            Context 'Adapter exist, Rss is enabled, no action required' {
                Mock -CommandName Get-NetAdapterRss -MockWith { 
                    @{ RssEnabled = $TestRssEnabled.State }
                }
                
                It 'Should return true' {
                    Test-TargetResource @TestRssEnabled | Should Be $true
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRss -Exactly 1
                }
            }

            Context 'Adapter exist, Rss is enabled, should be disabled' {
                Mock -CommandName Get-NetAdapterRss -MockWith { 
                    @{ RssEnabled = $TestRssEnabled.State }
                }
                
                It 'Should return false' {
                    Test-TargetResource @TestRssDisabled | Should Be $false
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRss -Exactly 1
                }
            }

            Context 'Adapter exist, Rss is disabled, no action required' {
                Mock -CommandName Get-NetAdapterRss -MockWith { 
                    @{ RssEnabled = $TestRssDisabled.State }
                }
                
                It 'Should return true' {
                    Test-TargetResource @TestRssDisabled | Should Be $true
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRss -Exactly 1
                }
            }

            Context 'Adapter exist, Rss is disabled , should be enabled.' {
                Mock -CommandName Get-NetAdapterRss -MockWith { 
                    @{ RssEnabled = $TestRssDisabled.State }
                }
                
                It 'Should return false' {
                    Test-TargetResource @TestRssEnabled | Should Be $false
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRss -Exactly 1
                }
            }

            # Adapter
            Context 'Adapter does not exist' {
                Mock -CommandName Get-NetAdapterRss -MockWith { throw 'Network adapter not found' }

                It 'Should throw an exception' {
                    { Set-TargetResource @TestAdapterNotFound } | Should throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRss -Exactly 1 
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
