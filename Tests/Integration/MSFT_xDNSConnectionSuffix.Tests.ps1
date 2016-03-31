$Global:DSCModuleName      = 'xNetworking'
$Global:DSCResourceName    = 'MSFT_xDnsConnectionSuffix'

#region HEADER
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}
else
{
    & git @('-C',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Integration 
#endregion

# Using try/finally to always cleanup even if something awful happens.
try
{
    #region Integration Tests
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($Global:DSCResourceName).config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    Describe "$($Global:DSCResourceName)_Integration" {
        # Configure Loopback Adapter
        if ($env:APPVEYOR) {
            # Running in AppVeyor so force silent install of LoopbackAdapter
            $PSBoundParameters.Force = $true
        }

        $LoopbackAdapterModuleName = 'LoopbackAdapter'
        $LoopbackAdapterModulePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\$LoopbackAdapterModuleName"
        $LoopbackAdapterModule = Install-ModuleFromPowerShellGallery `
            -ModuleName $LoopbackAdapterModuleName `
            -ModulePath $LoopbackAdapterModulePath `
            @PSBoundParameters

        if ($LoopbackAdapterModule) {
            # Import the module if it is available
            $LoopbackAdapterModule | Import-Module -Force
        }
        else
        {
            # Module could not/would not be installed - so warn user that tests will fail.
            Throw 'LoopbackAdapter Module could not be installed.'
        }

        $null = New-LoopbackAdapter `
            -Name $TestDnsConnectionSuffix.InterfaceAlias `
            @PSBoundParameters

        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($Global:DSCResourceName)_Config -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object {$_.ConfigurationName -eq "$($Global:DSCResourceName)_Config"}
            $current.InterfaceAlias                 | Should Be $TestDnsConnectionSuffix.InterfaceAlias
            $current.ConnectionSpecificSuffix       | Should Be $TestDnsConnectionSuffix.ConnectionSpecificSuffix
            $current.RegisterThisConnectionsAddress | Should Be $TestDnsConnectionSuffix.RegisterThisConnectionsAddress
            $current.Ensure                         | Should Be $TestDnsConnectionSuffix.Ensure
        }

        # Remove Loopback Adapter
        Remove-LoopbackAdapter `
            -Name $TestDnsConnectionSuffix.InterfaceAlias `
            @PSBoundParameters
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
