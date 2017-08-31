$script:DSCModuleName   = 'xNetworking'
$script:DSCResourceName = 'MSFT_xNetAdapterRsc'

#region HEADER
# Unit Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xNetworking'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}
Get-ChildItem (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\') -Recurse -Force | Unblock-File

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

        $TestAllRscEnabled = @{
            Name     = 'Ethernet'
            Protocol = 'All'
            State    = $true
        }

        $TestAllRscDisabled = @{
            Name     = 'Ethernet'
            Protocol = 'All'
            State    = $false
        }
        $TestIPv4RscEnabled = @{
            Name     = 'Ethernet'
            Protocol = 'IPv4'
            State    = $true
        }

        $TestIPv4RscDisabled = @{
            Name     = 'Ethernet'
            Protocol = 'IPv4'
            State    = $false
        }

        $TestIPv6RscEnabled = @{
            Name     = 'Ethernet'
            Protocol = 'IPv6'
            State    = $true
        }

        $TestIPv6RscDisabled = @{
            Name     = 'Ethernet'
            Protocol = 'IPv6'
            State    = $false
        }

        $TestAdapterNotFound = @{
            Name     = 'Eth'
            Protocol = 'IPv4'
            State    = $true
        }


        Describe "$($script:DSCResourceName)\Get-TargetResource" {
             Context 'Adapter exist and Rsc is enabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv4Enabled = $TestAllRscEnabled.StateIPv4
					   IPv6Enabled = $TestAllRscEnabled.StateIPv6}
                }

                It 'Should return the Rsc state' {
                    $result = Get-TargetResource @TestAllRscEnabled
                    $result.StateIPv4 | Should Be $TestAllRscEnabled.StateIPv4
					$result.StateIPv6 | Should Be $TestAllRscEnabled.StateIPv6
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                }
            }

            Context 'Adapter exist and Rsc is disabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv4Enabled = $TestAllRscDisabled.StateIPv4
					   IPv6Enabled = $TestAllRscDisabled.StateIPv6}
                }

                It 'Should return the Rsc state' {
                    $result = Get-TargetResource @TestAllRscDisabled
                    $result.StateIPv4 | Should Be $TestAllRscDisabled.StateIPv4
					$result.StateIPv6 | Should Be $TestAllRscDisabled.StateIPv6

                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                }
            }


            Context 'Adapter exist and Rsc for IPv4 is enabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv4Enabled = $TestIPv4RscEnabled.State }
                }

                It 'Should return the Rsc state of IPv4' {
                    $result = Get-TargetResource @TestIPv4RscEnabled
                    $result.State | Should Be $TestIPv4RscEnabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                }
            }

            Context 'Adapter exist and Rsc for IPv4 is disabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv4Enabled = $TestIPv4RscDisabled.State }
                }

                It 'Should return the Rsc state of IPv4' {
                    $result = Get-TargetResource @TestIPv4RscDisabled
                    $result.State | Should Be $TestIPv4RscDisabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                }
            }

            Context 'Adapter exist and Rsc for IPv6 is enabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv6Enabled = $TestIPv6RscEnabled.State }
                }

                It 'Should return the Rsc state of IPv6' {
                    $result = Get-TargetResource @TestIPv6RscEnabled
                    $result.State | Should Be $TestIPv6RscEnabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                }
            }

            Context 'Adapter exist and Rsc for IPv6 is disabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv6Enabled = $TestIPv6RscDisabled.State }
                }

                It 'Should return the Rsc state of IPv6' {
                    $result = Get-TargetResource @TestIPv6RscDisabled
                    $result.State | Should Be $TestIPv6RscDisabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                }
            }

            Context 'Adapter does not exist' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { throw 'Network adapter not found' }

                It 'Should throw an exception' {
                    { Get-TargetResource @TestAdapterNotFound } | Should throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1 
                }
            }
        }

        Describe "$($script:DSCResourceName)\Set-TargetResource" {
            
            # All
            Context 'Adapter exist, Rsc is enabled, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv4Enabled = $TestAllRscEnabled.State
					   IPv6Enabled = $TestAllRscEnabled.State}
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestAllRscEnabled } | Should Not Throw
                }
                
                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly 0
                }
            }

            Context 'Adapter exist, Rsc is enabled, should be disabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv4Enabled = $TestAllRscEnabled.State 
					   IPv6Enabled = $TestAllRscEnabled.State }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestAllRscDisabled } | Should Not Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly 1
                }
            }

            Context 'Adapter exist, Rsc is disabled, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv4Enabled = $TestAllRscDisabled.State
					   IPv6Enabled = $TestAllRscDisabled.State}
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestAllRscDisabled } | Should Not Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly 0
                }
            }

            Context 'Adapter exist, Rsc is disabled, should be enabled.' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv4Enabled = $TestAllRscDisabled.State 
					   IPv6Enabled = $TestAllRscDisabled.State}
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestAllRscEnabled } | Should Not Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly 1
                }
            }

            # IPv4
            Context 'Adapter exist, Rsc is enabled for IPv4, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv4Enabled = $TestIPv4RscEnabled.State }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestIPv4RscEnabled } | Should Not Throw
                }
                
                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly 0
                }
            }

            Context 'Adapter exist, Rsc is enabled for IPv4, should be disabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv4Enabled = $TestIPv4RscEnabled.State }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestIPv4RscDisabled } | Should Not Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly 1
                }
            }

            Context 'Adapter exist, Rsc is disabled for IPv4, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv4Enabled = $TestIPv4RscDisabled.State }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestIPv4RscDisabled } | Should Not Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly 0
                }
            }

            Context 'Adapter exist, Rsc is disabled for IPv4, should be enabled.' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv4Enabled = $TestIPv4RscDisabled.State }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestIPv4RscEnabled } | Should Not Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly 1
                }
            }

            # IPv6
            Context 'Adapter exist, Rsc is enabled for IPv6, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv6Enabled = $TestIPv6RscEnabled.State }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestIPv6RscEnabled } | Should Not Throw
                }
                
                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly 0
                }
            }

            Context 'Adapter exist, Rsc is enabled for IPv6, should be disabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv6Enabled = $TestIPv6RscEnabled.State }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestIPv6RscDisabled } | Should Not Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly 1
                }
            }

            Context 'Adapter exist, Rsc is disabled for IPv6, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv6Enabled = $TestIPv6RscDisabled.State }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestIPv6RscDisabled } | Should Not Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly 0
                }
            }

            Context 'Adapter exist, Rsc is disabled for IPv6, should be enabled.' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv6Enabled = $TestIPv6RscDisabled.State }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestIPv6RscEnabled } | Should Not Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly 1
                }
            }

            # Adapter
            Context 'Adapter does not exist' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { throw 'Network adapter not found' }

                It 'Should throw an exception' {
                    { Set-TargetResource @TestAdapterNotFound } | Should throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1 
                }
            }

        }

        Describe "$($script:DSCResourceName)\Test-TargetResource" {
            # All
            Context 'Adapter exist, Rsc is enabled, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv4Enabled = $TestAllRscEnabled.State 
					   IPv6Enabled = $TestAllRscEnabled.State}
                }
                
                It 'Should return true' {
                    Test-TargetResource @TestAllRscEnabled | Should Be $true
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                }
            }

            Context 'Adapter exist, Rsc is enabled, should be disabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv4Enabled = $TestAllRscEnabled.State 
					   IPv6Enabled = $TestAllRscEnabled.State }
                }
                
                It 'Should return false' {
                    Test-TargetResource @TestAllRscDisabled | Should Be $false
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                }
            }

            Context 'Adapter exist, Rsc is disabled, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv4Enabled = $TestAllRscDisabled.State
					   IPv6Enabled = $TestAllRscDisabled.State}
                }
                
                It 'Should return true' {
                    Test-TargetResource @TestAllRscDisabled | Should Be $true
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                }
            }

            Context 'Adapter exist, Rsc is disabled, should be enabled.' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ AllEnabled = $TestAllRscDisabled.State }
                }
                
                It 'Should return false' {
                    Test-TargetResource @TestAllRscEnabled | Should Be $false
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                }
            }

            # IPv4
            Context 'Adapter exist, Rsc is enabled for IPv4, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv4Enabled = $TestIPv4RscEnabled.State }
                }
                
                It 'Should return true' {
                    Test-TargetResource @TestIPv4RscEnabled | Should Be $true
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                }
            }

            Context 'Adapter exist, Rsc is enabled for IPv4, should be disabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv4Enabled = $TestIPv4RscEnabled.State }
                }
                
                It 'Should return false' {
                    Test-TargetResource @TestIPv4RscDisabled | Should Be $false
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                }
            }

            Context 'Adapter exist, Rsc is disabled for IPv4, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv4Enabled = $TestIPv4RscDisabled.State }
                }
                
                It 'Should return true' {
                    Test-TargetResource @TestIPv4RscDisabled | Should Be $true
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                }
            }

            Context 'Adapter exist, Rsc is disabled for IPv4, should be enabled.' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv4Enabled = $TestIPv4RscDisabled.State }
                }
                
                It 'Should return false' {
                    Test-TargetResource @TestIPv4RscEnabled | Should Be $false
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                }
            }

            # IPv6
            Context 'Adapter exist, Rsc is enabled for IPv6, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv6Enabled = $TestIPv6RscEnabled.State }
                }
                
                It 'Should return true' {
                    Test-TargetResource @TestIPv6RscEnabled | Should Be $true
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                }
            }

            Context 'Adapter exist, Rsc is enabled for IPv6, should be disabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv6Enabled = $TestIPv6RscEnabled.State }
                }
                
                It 'Should return false' {
                    Test-TargetResource @TestIPv6RscDisabled | Should Be $false
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                }
            }

            Context 'Adapter exist, Rsc is disabled for IPv6, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv6Enabled = $TestIPv6RscDisabled.State }
                }
                
                It 'Should return true' {
                    Test-TargetResource @TestIPv6RscDisabled | Should Be $true
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                }
            }

            Context 'Adapter exist, Rsc is disabled for IPv6, should be enabled.' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { 
                    @{ IPv6Enabled = $TestIPv6RscDisabled.State }
                }
                
                It 'Should return false' {
                    Test-TargetResource @TestIPv6RscEnabled | Should Be $false
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1
                }
            }

            # Adapter
            Context 'Adapter does not exist' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { throw 'Network adapter not found' }

                It 'Should throw an exception' {
                    { Set-TargetResource @TestAdapterNotFound } | Should throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly 1 
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

# SIG # Begin signature block
# MIID3QYJKoZIhvcNAQcCoIIDzjCCA8oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5ETul4ea5sNwkroQNZ0CFp7d
# gomgggIDMIIB/zCCAWigAwIBAgIQ8pqz2vlvr7FO4N97cGnyUDANBgkqhkiG9w0B
# AQUFADAQMQ4wDAYDVQQDEwVBdGRoZTAeFw0xNTEyMzEyMzAwMDBaFw0yMTEyMzEy
# MzAwMDBaMBAxDjAMBgNVBAMTBUF0ZGhlMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCB
# iQKBgQCiTZj/l4n4hjDCfi/lel2SRk5tyz1fnzSyJIATkfBcs9Zh4V2NUtYfYeJH
# 31+VSlkcSBrHZ9RRsw8luuZg8CKXlbeK0tpVaAcg+ToFHC7WbJ6RQ5wxbs0jstJX
# zc9ef8E2vEs3FScHMj8i3cnIoi551MKNy/EwYy4UKk3sS2fsowIDAQABo1owWDAT
# BgNVHSUEDDAKBggrBgEFBQcDAzBBBgNVHQEEOjA4gBDXoxziP+sYnBed6JU7bM/7
# oRIwEDEOMAwGA1UEAxMFQXRkaGWCEPKas9r5b6+xTuDfe3Bp8lAwDQYJKoZIhvcN
# AQEFBQADgYEAk83se/T5WG/BhwEEezGglMfs2XrToVl4h0icJb/PQkB9/mtNRBjY
# d0EpfZnnioGOBDRjMXFpcH79XOOm+lLZcbRWUQRA6g9AMSk15e20+Nh7u5UINwHm
# BT3NKdtxAgsei2YKaAQc/tbvZuaZCCHMMmyiq51DKCQoMJgGblxBubcxggFEMIIB
# QAIBATAkMBAxDjAMBgNVBAMTBUF0ZGhlAhDymrPa+W+vsU7g33twafJQMAkGBSsO
# AwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEM
# BgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqG
# SIb3DQEJBDEWBBTEcBN7rLzZxlsxywXsYarPpwKp3zANBgkqhkiG9w0BAQEFAASB
# gJvf/7BultjK0kxCwDPGW2LrmV4/3rI+dAxeZsgddryQLqsCxRivXJjZYi+wJCSl
# WNIQU5llH9pNFQ5iDoT6Fyahl2OIJYyZ+IYAODqoq0fxbfpxfuh31e5nkJNP/c07
# JJhanU4cUCPeYj6xHJ/u4ESl/UaKxwg3PI2NPgKlxuht
# SIG # End signature block
