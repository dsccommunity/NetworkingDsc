function Invoke-xNetworkingTest
{
    [CmdletBinding()]
    param
    (
        [System.String] $TestResultsFile,

        [System.String] $DscTestsPath
    )

    Write-Verbose -Message 'Commencing all xNetworking tests'

    $repoDir = Join-Path -Path $PSScriptRoot -ChildPath "..\" -Resolve

    $testCoverageFiles = @()
    Get-ChildItem -Path "$repoDir\modules\xNetworking\DSCResources\**\*.psm1" -Recurse | ForEach-Object {
        if ($_.FullName -notlike '*\DSCResource.Tests\*') {
            $testCoverageFiles += $_.FullName
        }
    }

    $testResultSettings = @{ }
    if ([String]::IsNullOrEmpty($TestResultsFile) -eq $false) {
        $testResultSettings.Add('OutputFormat', 'NUnitXml' )
        $testResultSettings.Add('OutputFile', $TestResultsFile)
    }

    Import-Module -Name "$repoDir\modules\xNetworking\xNetworking.psd1"
    $testsToRun = @()

    # Run Unit Tests
    $unitTestsPath = Join-Path -Path $repoDir -ChildPath 'Tests\Unit'
    $testsToRun += @( (Get-ChildItem -Path $unitTestsPath).FullName )

    # Integration Tests
    $integrationTestsPath = Join-Path -Path $repoDir -ChildPath 'Tests\Integration'
    $testsToRun += @( (Get-ChildItem -Path $integrationTestsPath -Filter '*.Tests.ps1').FullName )

    # DSC Common Tests
    if ($PSBoundParameters.ContainsKey('DscTestsPath') -eq $true)
    {
        $testsToRun += @( $DscTestsPath )
    }

    $results = Invoke-Pester -Script $testsToRun `
        -CodeCoverage $testCoverageFiles `
        -PassThru @testResultSettings

    return $results
}
