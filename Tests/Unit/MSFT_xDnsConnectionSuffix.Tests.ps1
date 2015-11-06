if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = 'MSFT_xDnsConnectionSuffix'
Import-Module (Join-Path $RepoRoot "DSCResources\$ModuleName\$ModuleName.psm1") -Force;

Describe $ModuleName {

    InModuleScope $ModuleName {

        $testDnsSuffix = 'example.local';
        $testInterfaceAlias = 'Ethernet';
        $testDnsSuffixParams = @{
            InterfaceAlias = $testInterfaceAlias;
            ConnectionSpecificSuffix = $testDnsSuffix;
        }

        $fakeDnsSuffixPresent = @{
            InterfaceAlias = $testInterfaceAlias;
            ConnectionSpecificSuffix = $testDnsSuffix;
            RegisterThisConnectionsAddress = $true;
            UseSuffixWhenRegistering = $false;
        }
        
        $fakeDnsSuffixMismatch = $fakeDnsSuffixPresent.Clone();
        $fakeDnsSuffixMismatch['ConnectionSpecificSuffix'] = 'mismatch.local';

        $fakeDnsSuffixAbsent = $fakeDnsSuffixPresent.Clone();
        $fakeDnsSuffixAbsent['ConnectionSpecificSuffix'] = '';


        Context 'Validates "Get-TargetResource" method' {

            It 'Returns a "System.Collections.Hashtable" object type' {
                Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixPresent; }

                $targetResource = Get-TargetResource @testDnsSuffixParams;
                
                $targetResource -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Returns "Present" when DNS suffix matches and "Ensure" = "Present"' {
                Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixPresent; }

                $targetResource = Get-TargetResource @testDnsSuffixParams;
                
                $targetResource.Ensure | Should Be 'Present';
            }

            It 'Returns "Absent" when DNS suffix does not match and "Ensure" = "Present"' {
                Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixMismatch; }

                $targetResource = Get-TargetResource @testDnsSuffixParams;
                
                $targetResource.Ensure | Should Be 'Absent';
            }

            It 'Returns "Absent" when no DNS suffix is defined and "Ensure" = "Present"' {
                Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixAbsent; }

                $targetResource = Get-TargetResource @testDnsSuffixParams;
                
                $targetResource.Ensure | Should Be 'Absent';
            }

            It 'Returns "Absent" when no DNS suffix is defined and "Ensure" = "Absent"' {
                Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixAbsent; }

                $targetResource = Get-TargetResource @testDnsSuffixParams -Ensure Absent;
                
                $targetResource.Ensure | Should Be 'Absent';
            }

            It 'Returns "Present" when DNS suffix is defined and "Ensure" = "Absent"' {
                Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixPresent; }

                $targetResource = Get-TargetResource @testDnsSuffixParams -Ensure Absent;
                
                $targetResource.Ensure | Should Be 'Present';
            }

        } #end Context 'Validates "Get-TargetResource" method'

        Context 'Validates "Test-TargetResource" method' {

            It 'Passes when all properties match and "Ensure" = "Present"' {
                Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixPresent; }

                $targetResource = Test-TargetResource @testDnsSuffixParams;

                $targetResource | Should Be $true;
            }
            It 'Passes when no DNS suffix is registered and "Ensure" = "Absent"' {
                Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixAbsent; }

                $targetResource = Test-TargetResource @testDnsSuffixParams -Ensure Absent;

                $targetResource | Should Be $true;
            }
            It 'Passes when "RegisterThisConnectionsAddress" setting is correct' {
                Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixPresent; }

                $targetResource = Test-TargetResource @testDnsSuffixParams -RegisterThisConnectionsAddress $true;

                $targetResource | Should Be $true;
            }
            It 'Passes when "UseSuffixWhenRegistering" setting is correct' {
                Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixPresent; }

                $targetResource = Test-TargetResource @testDnsSuffixParams -UseSuffixWhenRegistering $false;

                $targetResource | Should Be $true;
            }

            It 'Fails when no DNS suffix is registered and "Ensure" = "Present"' {
                Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixAbsent; }

                $targetResource = Test-TargetResource @testDnsSuffixParams;

                $targetResource | Should Be $false;
            }
            It 'Fails when the registered DNS suffix is incorrect and "Ensure" = "Present"' {
                Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixMismatch; }

                $targetResource = Test-TargetResource @testDnsSuffixParams;

                $targetResource | Should Be $false;
            }
            It 'Fails when a DNS suffix is registered and "Ensure" = "Absent"' {
                Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixPresent; }

                $targetResource = Test-TargetResource @testDnsSuffixParams -Ensure Absent;

                $targetResource | Should Be $false;
            }
            It 'Fails when "RegisterThisConnectionsAddress" setting is incorrect' {
                Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixPresent; }

                $targetResource = Test-TargetResource @testDnsSuffixParams -RegisterThisConnectionsAddress $false;

                $targetResource | Should Be $false;
            }
            It 'Fails when "UseSuffixWhenRegistering" setting is incorrect' {
                Mock Get-DnsClient { return [PSCustomObject] $fakeDnsSuffixPresent; }

                $targetResource = Test-TargetResource @testDnsSuffixParams -UseSuffixWhenRegistering $true;

                $targetResource | Should Be $false;
            }

        } #end Context 'Validates "Test-TargetResource" method'

        Context 'Validates "Set-TargetResource" method' {

            It 'Calls "Set-DnsClient" with specified DNS suffix when "Ensure" = "Present"' {
                Mock Set-DnsClient -ParameterFilter { $InterfaceAlias -eq $testInterfaceAlias -and $ConnectionSpecificSuffix -eq $testDnsSuffix } { }

                Set-TargetResource @testDnsSuffixParams;

                Assert-MockCalled Set-DnsClient -ParameterFilter { $InterfaceAlias -eq $testInterfaceAlias -and $ConnectionSpecificSuffix -eq $testDnsSuffix } -Scope It;
            }
            It 'Calls "Set-DnsClient" with no DNS suffix when "Ensure" = "Absent"' {
                Mock Set-DnsClient -ParameterFilter { $InterfaceAlias -eq $testInterfaceAlias -and $ConnectionSpecificSuffix -eq '' } { }

                Set-TargetResource @testDnsSuffixParams -Ensure Absent;

                Assert-MockCalled Set-DnsClient -ParameterFilter { $InterfaceAlias -eq $testInterfaceAlias -and $ConnectionSpecificSuffix -eq '' } -Scope It;
            }

        } #end Context 'Validates "Set-TargetResource" method'
    
    } #end InModuleScope $ModuleName

}
