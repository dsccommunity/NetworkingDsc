$script:dscModuleName = 'xNetworking'
$script:dscResourceName = 'MSFT_xNetBIOS'

#region HEADER
# Unit Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xNetworking'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) ) {
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$testEnvironment = Initialize-TestEnvironment -DSCModuleName $script:dscModuleName -DSCResourceName $script:dscResourceName -TestType Unit
#endregion HEADER

# Begin Testing
try {
    #region Pester Tests
    InModuleScope $script:dscResourceName {

        $interfaceAlias = Get-NetAdapter -Physical | Select-Object -First 1 -ExpandProperty Name
        
        #region Function Get-TargetResource
        Describe "MSFT_xNetBIOS\Get-TargetResource" {

            Context 'TcpipNetbiosOptions = 0, WINSEnableLMHostsLookup = $true' {
                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    [PSCustomObject]@{                    
                        InterfaceAlias          = 'Ethernet'
                        TcpipNetbiosOptions     = 0
                        WINSEnableLMHostsLookup = $true
                    }
                }

                It 'Returns a hashtable' {
                    $targetResource = Get-TargetResource -InterfaceAlias $interfaceAlias -Setting Default -EnableLmhostsLookup $true
                    $targetResource -is [System.Collections.Hashtable] | Should Be $true
                }

                It "NetBIOS over TCP/IP should be 'Default'" {
                    $result = Get-TargetResource -InterfaceAlias $interfaceAlias -Setting Default
                    $result.Setting | should be Default
                }

                It "NetBIOS over TCP/IP should be 'Default' and WINSEnableLMHostsLookup should be true" {
                    $result = Get-TargetResource -InterfaceAlias $interfaceAlias -Setting Enable -EnableLmhostsLookup $false
                    $result.Setting | should be Default
                    $result.EnableLmhostsLookup | should be $true
                }
            }
            
            Context 'TcpipNetbiosOptions = 2, WINSEnableLMHostsLookup = $false' {
                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    [PSCustomObject]@{                    
                        InterfaceAlias          = 'Ethernet'
                        TcpipNetbiosOptions     = 2
                        WINSEnableLMHostsLookup = $false
                    }
                }

                It "NetBIOS over TCP/IP should be 'Disable' and WINSEnableLMHostsLookup should be false" {
                    $result = Get-TargetResource -InterfaceAlias $interfaceAlias -Setting Enable -EnableLmhostsLookup $false
                    $result.Setting | should be Disable
                    $result.EnableLmhostsLookup | should be $false
                }
            }
            #endregion


            #region Function Test-TargetResource
            Describe "MSFT_xNetBIOS\Test-TargetResource" {
                Context "Invoking with NetBIOS over TCP/IP set to 'Default' and EnableLmhostsLookup untouched" {

                    Mock -CommandName Get-CimAssociatedInstance -MockWith { 
                        [PSCustomObject]@{                    
                            InterfaceAlias      = 'Ethernet'
                            TcpipNetbiosOptions = 0
                        }
                    }

                    It "Should return true when value 'Default' is set" {
                        Test-TargetResource -InterfaceAlias $interfaceAlias -Setting Default | Should Be $true
                    }
                    It "Should return false when value 'Disable' is set" {
                        Test-TargetResource -InterfaceAlias $interfaceAlias -Setting Disable | Should Be $false
                    }
                }

                Context "Invoking with NetBIOS over TCP/IP set to 'Disable' and EnableLmhostsLookup untouched" {

                    Mock -CommandName Get-CimAssociatedInstance -MockWith { 
                        [PSCustomObject]@{                    
                            InterfaceAlias      = 'Ethernet'
                            TcpipNetbiosOptions = 2
                        }
                    }

                    It "Should return true when value 'Disable' is set" {
                        Test-TargetResource -InterfaceAlias $interfaceAlias -Setting Disable | Should Be $true
                    }
                    It "Should return false when value 'Enable' is set" {
                        Test-TargetResource -InterfaceAlias $interfaceAlias -Setting Enable | Should Be $false
                    }
                }

                Context "Invoking with NetBIOS over TCP/IP set to 'Enable' and EnableLmhostsLookup untouched" {

                    Mock -CommandName Get-CimAssociatedInstance -MockWith { 
                        [PSCustomObject]@{                    
                            InterfaceAlias      = 'Ethernet'
                            TcpipNetbiosOptions = 1
                        }
                    }

                    It "Should return true when value 'Enable' is set" {
                        Test-TargetResource -InterfaceAlias $interfaceAlias -Setting Enable | Should Be $true
                    }
                    It "Should return false when value 'Disable' is set" {
                        Test-TargetResource -InterfaceAlias $interfaceAlias -Setting Disable | Should Be $false
                    }
                }
            
                Context "Invoking with NetBIOS over TCP/IP set to 'Enable' and EnableLmhostsLookup 'true'" {

                    Mock -CommandName Get-CimAssociatedInstance -MockWith { 
                        [PSCustomObject]@{                    
                            InterfaceAlias          = 'Ethernet'
                            TcpipNetbiosOptions     = 1
                            WINSEnableLMHostsLookup = $true
                        }
                    }

                    It "Should return true when Setting is 'Enable' and EnableLmhostsLookup is 'true'" {
                        Test-TargetResource -InterfaceAlias $interfaceAlias -Setting Enable -EnableLmhostsLookup $true| Should Be $true
                    }
                    It "Should return false when Setting is 'Enable' but EnableLmhostsLookup is 'false'" {
                        Test-TargetResource -InterfaceAlias $interfaceAlias -Setting Enable -EnableLmhostsLookup $false | Should Be $false
                    }
                }
            
                Context "Invoking with NetBIOS over TCP/IP set to 'Disable' and EnableLmhostsLookup 'false'" {

                    Mock -CommandName Get-CimAssociatedInstance -MockWith { 
                        [PSCustomObject]@{                    
                            InterfaceAlias          = 'Ethernet'
                            TcpipNetbiosOptions     = 2
                            WINSEnableLMHostsLookup = $false
                        }
                    }

                    It "Should return true when Setting is 'Enable' and EnableLmhostsLookup is 'true'" {
                        Test-TargetResource -InterfaceAlias $interfaceAlias -Setting Disable -EnableLmhostsLookup $false | Should Be $true
                    }
                    It "Should return false when Setting is 'Enable' but EnableLmhostsLookup is 'false'" {
                        Test-TargetResource -InterfaceAlias $interfaceAlias -Setting Disable -EnableLmhostsLookup $true | Should Be $false
                    }
                }

                Context 'Invoking with NonExisting Network Adapter' {
                    Mock -CommandName Get-CimAssociatedInstance -MockWith { }
                    $errorMessage = ($LocalizedData.NICNotFound -f 'BogusAdapter')
                    It 'Should throw ObjectNotFound exception' {
                        { Test-TargetResource -InterfaceAlias BogusAdapter -Setting Enable } | Should Throw $errorMessage
                    }
                }
            }
            #endregion

            #region Function Set-TargetResource
            Describe "MSFT_xNetBIOS\Set-TargetResource" {

                Context "Setting NetBIOS to 'Default' only" {

                    Mock -CommandName Invoke-CimMethod
                    Mock -CommandName Set-ItemProperty

                    It "Should call 'Set-ItemProperty' and 'Invoke-CimMethod'" {
                        $null = Set-TargetResource -InterfaceAlias $interfaceAlias -Setting Default

                        Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 1
                        Assert-MockCalled -CommandName Invoke-CimMethod -Exactly -Times 0
                    }
                }

                Context "Setting NetBIOS to 'Default' and disable EnableLmhostsLookup" {

                    Mock -CommandName Invoke-CimMethod
                    Mock -CommandName Set-ItemProperty

                    It "Should call 'Set-ItemProperty'" {
                        $null = Set-TargetResource -InterfaceAlias $interfaceAlias -Setting Default -EnableLmhostsLookup $true

                        Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 1
                        Assert-MockCalled -CommandName Invoke-CimMethod -Exactly -Times 1
                    }
                }
            }
        }
        #endregion
    }
    #endregion
}
finally {
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $testEnvironment
    #endregion
}
