$here = Split-Path -Parent $MyInvocation.MyCommand.Path

if (! (Get-Module xDSCResourceDesigner))
{
    Import-Module -Name xDSCResourceDesigner
}

Describe 'Schema Validation HostsFile' {
    It 'should pass Test-xDscResource' {
        $path = Join-Path -Path $((Get-Item $here).parent.FullName) -ChildPath 'DSCResources\HostsFile'
        $result = Test-xDscResource $path
        $result | Should Be $true
    }

    It 'should pass Test-xDscResource' {
        $path = Join-Path -Path $((get-item $here).parent.FullName) -ChildPath 'DSCResources\HostsFile\HostsFile.schema.mof'
        $result = Test-xDscSchema $path
        $result | Should Be $true
    }
}

if (Get-Module HostsFile -All)
{
    Get-Module HostsFile -All | Remove-Module
}

Import-Module -Name $PSScriptRoot\..\DSCResources\HostsFile -Force -DisableNameChecking
