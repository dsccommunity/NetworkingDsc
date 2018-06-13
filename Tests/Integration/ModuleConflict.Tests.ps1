$script:DSCModuleName      = 'NetworkingDsc'
<#
    These integration tests ensure that exported cmdlets names do not conflict
    with any other names that are exposed by other common resource kit modules.
#>
$script:ModulesToTest = @( 'StorageDsc','ComputerManagementDsc','DFSDsc' )

#region HEADER
# Integration Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\NetworkingDsc'

if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
Import-Module (Join-Path -Path $script:moduleRoot -ChildPath "$($script:DSCModuleName).psd1") -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName 'All' `
    -TestType Integration

#endregion

# Using try/finally to always cleanup even if something awful happens.
try
{
    Describe "$($script:DSCModuleName)_CommonModuleConflict" {

        foreach ($moduleToTest in $script:ModulesToTest)
        {
            It "Should be able to install DSC Resource module '$moduleToTest'" {
                {
                    Install-Module -Name $moduleToTest -ErrorAction Stop
                } | Should -Not -Throw
            }
        }
    }
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
