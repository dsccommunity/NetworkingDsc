$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_DnsClientNrptGlobal'

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
$moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$resourceData = Import-LocalizedData `
    -BaseDirectory (Join-Path -Path $moduleRoot -ChildPath 'Source\DscResources\DSC_DnsClientNrptGlobal') `
    -FileName 'DSC_DnsClientNrptGlobal.data.psd1'

$parameterList = $resourceData.ParameterList | Where-Object -Property IntTest -eq $True

# Begin Testing
try
{
    Describe 'DnsClientNrptGlobal Integration Tests' {
        # Backup the existing settings
        $script:currentDnsClientNrptGlobal = Get-DnsClientNrptGlobal

        # Set the DNS Client Global settings to known values
        Set-DnsClientNrptGlobal `
            -EnableDAForAllNetworks 'EnableAlways' `
            -QueryPolicy 'QueryIPv6Only' `
            -SecureNameQueryFallback 'FallbackSecure'

        $configData = @{
            AllNodes = @(
                @{
                    NodeName                = 'localhost'
                    EnableDAForAllNetworks  = 'DisableDA'
                    QueryPolicy             = 'QueryBoth'
                    SecureNameQueryFallback = 'FallbackPrivate'
                }
            )
        }

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile

        Describe "$($script:dscResourceName)_Integration" {
            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
                    Start-DscConfiguration `
                        -Path $TestDrive `
                        -ComputerName localhost `
                        -Wait `
                        -Verbose `
                        -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            # Get the DNS Client Global Settings details
            $DnsClientNrptGlobalNew = Get-DnsClientNrptGlobal

            # Use the Parameters List to perform these tests
            foreach ($parameter in $parameterList)
            {
                $parameterCurrentValue = (Get-Variable -Name 'DnsClientNrptGlobalNew').value.$($parameter.name)
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
    Set-DnsClientNrptGlobal `
        -EnableDAForAllNetworks $script:currentDnsClientNrptGlobal.EnableDAForAllNetworks `
        -QueryPolicy $script:currentDnsClientNrptGlobal.QueryPolicy `
        -SecureNameQueryFallback $script:currentDnsClientNrptGlobal.SecureNameQueryFallback

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
