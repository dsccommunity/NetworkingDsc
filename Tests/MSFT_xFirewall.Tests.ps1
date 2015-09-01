$here = Split-Path -Parent $MyInvocation.MyCommand.Path

if (Get-Module MSFT_xFirewall -All)
{
    Get-Module MSFT_xFirewall -All | Remove-Module
}

Import-Module -Name $PSScriptRoot\..\DSCResources\MSFT_xFirewall -Force -DisableNameChecking
