$script:DSCModuleName   = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_DnsClientGlobalSetting'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Integration Test Template Version: 1.1.1
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
                NodeName         = 'localhost'
                SuffixSearchList = 'contoso.com'
                UseDevolution    = $True
                DevolutionLevel  = 2
            }
        )
    }

    #region Integration Tests
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile

    Describe "$($script:DSCResourceName)_Integration" {
        #region DEFAULT TESTS
        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:DSCResourceName)_Config" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData
                Start-DscConfiguration `
                    -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
        }
        #endregion

        # Get the DNS Client Global Settings details
        $dnsClientGlobalSettingNew = Get-DnsClientGlobalSetting

        # Use the Parameters List to perform these tests
        foreach ($parameter in $parameterList)
        {
            $parameterCurrentValue = (Get-Variable -Name 'dnsClientGlobalSettingNew').value.$($parameter.name)
            $parameterNewValue = (Get-Variable -Name configData).Value.AllNodes[0].$($parameter.Name)

            It "Should have set the '$parameterName' to '$parameterNewValue'" {
                $parameterCurrentValue | Should -Be $parameterNewValue
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
