$here = Split-Path -Parent $MyInvocation.MyCommand.Path

if (! (Get-Module xDSCResourceDesigner))
{
    Import-Module -Name xDSCResourceDesigner
}

Describe 'Schema Validation MSFT_xFirewall' {
    It 'should pass Test-xDscResource' {
        $path = Join-Path -Path $((Get-Item $here).parent.FullName) -ChildPath 'DSCResources\MSFT_xFirewall'
        $result = Test-xDscResource $path
        $result | Should Be $true
    }

    It 'should pass Test-xDscResource' {
        $path = Join-Path -Path $((get-item $here).parent.FullName) -ChildPath 'DSCResources\MSFT_xFirewall\MSFT_xFirewall.schema.mof'
        $result = Test-xDscSchema $path
        $result | Should Be $true
    }
}

if (Get-Module MSFT_xFirewall -All)
{
    Get-Module MSFT_xFirewall -All | Remove-Module
}

Import-Module -Name $PSScriptRoot\..\DSCResources\MSFT_xFirewall -Force -DisableNameChecking
