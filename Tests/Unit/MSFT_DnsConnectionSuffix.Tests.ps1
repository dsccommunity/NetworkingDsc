$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_DnsConnectionSuffix'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
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
    -TestType Unit
#endregion HEADER


# Begin Testing
try
{
    InModuleScope $script:DSCResourceName {

        $testDnsSuffix = 'example.local'
        $testInterfaceAlias = 'Ethernet'
        $testDnsSuffixParams = @{
            InterfaceAlias           = $testInterfaceAlias
            ConnectionSpecificSuffix = $testDnsSuffix
        }

        $fakeDnsSuffixPresent = @{
            InterfaceAlias                 = $testInterfaceAlias
            ConnectionSpecificSuffix       = $testDnsSuffix
            RegisterThisConnectionsAddress = $true
            UseSuffixWhenRegistering       = $false
        }

        $fakeDnsSuffixMismatch = $fakeDnsSuffixPresent.Clone()
        $fakeDnsSuffixMismatch['ConnectionSpecificSuffix'] = 'mismatch.local'

        $fakeDnsSuffixAbsent = $fakeDnsSuffixPresent.Clone()
        $fakeDnsSuffixAbsent['ConnectionSpecificSuffix'] = ''


        Describe 'MSFT_DnsConnectionSuffix\Get-TargetResource' -Tag 'Get' {
            Context 'Validates "Get-TargetResource" method' {
                It 'Should return a "System.Collections.Hashtable" object type' {
                    Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixPresent }

                    $targetResource = Get-TargetResource @testDnsSuffixParams

                    $targetResource -is [System.Collections.Hashtable] | Should -Be $true
                }

                It 'Should return "Present" when DNS suffix matches and "Ensure" = "Present"' {
                    Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixPresent }

                    $targetResource = Get-TargetResource @testDnsSuffixParams

                    $targetResource.Ensure | Should -Be 'Present'
                }

                It 'Should return "Absent" when DNS suffix does not match and "Ensure" = "Present"' {
                    Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixMismatch }

                    $targetResource = Get-TargetResource @testDnsSuffixParams

                    $targetResource.Ensure | Should -Be 'Absent'
                }

                It 'Should return "Absent" when no DNS suffix is defined and "Ensure" = "Present"' {
                    Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixAbsent }

                    $targetResource = Get-TargetResource @testDnsSuffixParams

                    $targetResource.Ensure | Should -Be 'Absent'
                }

                It 'Should return "Absent" when no DNS suffix is defined and "Ensure" = "Absent"' {
                    Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixAbsent }

                    $targetResource = Get-TargetResource @testDnsSuffixParams -Ensure Absent

                    $targetResource.Ensure | Should -Be 'Absent'
                }

                It 'Should return "Present" when DNS suffix is defined and "Ensure" = "Absent"' {
                    Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixPresent }

                    $targetResource = Get-TargetResource @testDnsSuffixParams -Ensure Absent

                    $targetResource.Ensure | Should -Be 'Present'
                }

            } #end Context 'Validates "Get-TargetResource" method'
        }

        Describe 'MSFT_DnsConnectionSuffix\Test-TargetResource' -Tag 'Test' {
            Context 'Validates "Test-TargetResource" method' {
                It 'Should pass when all properties match and "Ensure" = "Present"' {
                    Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixPresent }

                    $targetResource = Test-TargetResource @testDnsSuffixParams

                    $targetResource | Should -Be $true
                }

                It 'Should pass when no DNS suffix is registered and "Ensure" = "Absent"' {
                    Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixAbsent }

                    $targetResource = Test-TargetResource @testDnsSuffixParams -Ensure Absent

                    $targetResource | Should -Be $true
                }

                It 'Should pass when "RegisterThisConnectionsAddress" setting is correct' {
                    Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixPresent }

                    $targetResource = Test-TargetResource @testDnsSuffixParams -RegisterThisConnectionsAddress $true

                    $targetResource | Should -Be $true
                }

                It 'Should pass when "UseSuffixWhenRegistering" setting is correct' {
                    Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixPresent }

                    $targetResource = Test-TargetResource @testDnsSuffixParams -UseSuffixWhenRegistering $false

                    $targetResource | Should -Be $true
                }


                It 'Should fail when no DNS suffix is registered and "Ensure" = "Present"' {
                    Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixAbsent }

                    $targetResource = Test-TargetResource @testDnsSuffixParams

                    $targetResource | Should -Be $false
                }

                It 'Should fail when the registered DNS suffix is incorrect and "Ensure" = "Present"' {
                    Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixMismatch }

                    $targetResource = Test-TargetResource @testDnsSuffixParams

                    $targetResource | Should -Be $false
                }

                It 'Should fail when a DNS suffix is registered and "Ensure" = "Absent"' {
                    Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixPresent }

                    $targetResource = Test-TargetResource @testDnsSuffixParams -Ensure Absent

                    $targetResource | Should -Be $false
                }

                It 'Should fail when "RegisterThisConnectionsAddress" setting is incorrect' {
                    Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixPresent }

                    $targetResource = Test-TargetResource @testDnsSuffixParams -RegisterThisConnectionsAddress $false

                    $targetResource | Should -Be $false
                }

                It 'Should fail when "UseSuffixWhenRegistering" setting is incorrect' {
                    Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixPresent }

                    $targetResource = Test-TargetResource @testDnsSuffixParams -UseSuffixWhenRegistering $true

                    $targetResource | Should -Be $false
                }
            } #end Context 'Validates "Test-TargetResource" method'
        }

        Describe 'MSFT_DnsConnectionSuffix\Set-TargetResource' -Tag 'Set' {
            Context 'Validates "Set-TargetResource" method' {
                It 'Should call "Set-DnsClient" with specified DNS suffix when "Ensure" = "Present"' {
                    Mock Set-DnsClient -ParameterFilter { $InterfaceAlias -eq $testInterfaceAlias -and $ConnectionSpecificSuffix -eq $testDnsSuffix } { }

                    Set-TargetResource @testDnsSuffixParams

                    Assert-MockCalled Set-DnsClient -ParameterFilter { $InterfaceAlias -eq $testInterfaceAlias -and $ConnectionSpecificSuffix -eq $testDnsSuffix } -Scope It
                }

                It 'Should call "Set-DnsClient" with no DNS suffix when "Ensure" = "Absent"' {
                    Mock Set-DnsClient -ParameterFilter { $InterfaceAlias -eq $testInterfaceAlias -and $ConnectionSpecificSuffix -eq '' } { }

                    Set-TargetResource @testDnsSuffixParams -Ensure Absent

                    Assert-MockCalled Set-DnsClient -ParameterFilter { $InterfaceAlias -eq $testInterfaceAlias -and $ConnectionSpecificSuffix -eq '' } -Scope It
                }
            } #end Context 'Validates "Set-TargetResource" method'
        }
    } #end InModuleScope $DSCResourceName
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
