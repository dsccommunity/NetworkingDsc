$script:DSCModuleName   = 'xNetworking'
$script:DSCResourceName = 'MSFT_xDnsClientGlobalSetting'

#region HEADER
# Integration Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xNetworking'

if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration
#endregion

# Backup the existing settings
$CurrentDnsClientGlobalSetting = Get-DnsClientGlobalSetting

# Using try/finally to always cleanup even if something awful happens.
try
{
    # Import the Common Networking functions
    Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'Modules\NetworkingDsc.Common\NetworkingDsc.Common.psm1') -Force

    # Load the ParameterList from the data file.
    $resourceDataPath = Join-Path `
        -Path $script:moduleRoot `
        -ChildPath (Join-Path -Path 'DSCResources' -ChildPath $script:DSCResourceName)
    $resourceData = Import-LocalizedData `
        -BaseDirectory $resourceDataPath `
        -FileName "$($script:DSCResourceName).data.psd1"
    $parameterList = $resourceData.ParameterList

    # Set the DNS Client Global settings to known values
    Set-DnsClientGlobalSetting `
        -SuffixSearchList 'fabrikam.com' `
        -UseDevolution $False `
        -DevolutionLevel 4

    $configData = @{
        AllNodes = @(
            @{
                NodeName              = 'localhost'
                SuffixSearchList             = 'contoso.com'
                UseDevolution                = $True
                DevolutionLevel              = 2
            }
        )
    }

    #region Integration Tests
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile

    Describe "$($script:DSCResourceName)_Integration" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                & "$($script:DSCResourceName)_Config" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData
                Start-DscConfiguration `
                    -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        # Get the DNS Client Global Settings details
        $DnsClientGlobalSettingNew = Get-DnsClientGlobalSetting

        # Use the Parameters List to perform these tests
        foreach ($parameter in $parameterList)
        {
            $parameterSource = (Invoke-Expression -Command "`$DnsClientGlobalSettingNew.$($parameter.name)")
            $parameterNew = (Invoke-Expression -Command "`$configData.AllNodes[0].$($parameter.name)")
            It "Should have set the '$parameterName' to '$parameterNew'" {
                $parameterSource | Should Be $parameterNew
            }
        }
    }
    #endregion
}
finally
{
    # Clean up
    Set-DnsClientGlobalSetting `
        -SuffixSearchList $CurrentDnsClientGlobalSetting.SuffixSearchList `
        -UseDevolution $CurrentDnsClientGlobalSetting.UseDevolution `
        -DevolutionLevel $CurrentDnsClientGlobalSetting.DevolutionLevel

    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
