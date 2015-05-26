Remove-Module -Name MSFT_xFirewall -Force -ErrorAction SilentlyContinue
Import-Module -Name $PSScriptRoot\..\DSCResources\MSFT_xFirewall -Force -DisableNameChecking

if (! (Get-Module xDSCResourceDesigner))
{
    Import-Module -Name xDSCResourceDesigner -ErrorAction SilentlyContinue
}

Describe 'Schema Validation for MSFT_xFirewall' {
    $result = Test-xDscResource MSFT_xFirewall
    It 'should pass Test-xDscResource' {
        $result | Should Be $true
    }
}