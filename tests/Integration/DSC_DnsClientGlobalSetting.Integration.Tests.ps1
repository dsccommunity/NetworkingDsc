$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_DnsClientGlobalSetting'

try
{
    Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
}
catch [System.IO.FileNotFoundException]
{
    throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
}

$script:testEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType 'Integration'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

# Load the parameter List from the data file
$resourceData = Import-LocalizedData `
    -BaseDirectory (Join-Path -Path $script:moduleRoot -ChildPath 'Source\DscResources\DSC_DnsClientGlobalSetting') `
    -FileName 'DSC_DnsClientGlobalSetting.data.psd1'

$parameterList = $resourceData.ParameterList | Where-Object -Property IntTest -eq $True

# Begin Testing
try
{
    Describe 'DnsClientGlobalSetting Integration Tests' {
        # Backup the existing settings
        $script:currentDnsClientGlobalSetting = Get-DnsClientGlobalSetting

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
    }
}
finally
{
    # Clean up
    Set-DnsClientGlobalSetting `
        -SuffixSearchList $script:currentDnsClientGlobalSetting.SuffixSearchList `
        -UseDevolution $script:currentDnsClientGlobalSetting.UseDevolution `
        -DevolutionLevel $script:currentDnsClientGlobalSetting.DevolutionLevel

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
