$DSCModuleName      = 'xNetworking'
$DSCResourceName    = 'MSFT_xNetConnectionProfile'
$RelativeModulePath = "$DSCModuleName.psd1"

#region HEADER
# Temp Working Folder - always gets remove on completion
$WorkingFolder = Join-Path -Path $env:Temp -ChildPath $DSCResourceName

# Copy to Program Files for WMF 4.0 Compatability as it can only find resources in a few known places.
$moduleRoot = "${env:ProgramFiles}\WindowsPowerShell\Modules\$DSCModuleName"

# If this module already exists in the Modules folder, make a copy of it in
# the temporary folder so that it isn't accidentally used in this test.
if(-not (Test-Path -Path $moduleRoot))
{
    $null = New-Item -Path $moduleRoot -ItemType Directory
}
else
{
    # Copy the existing folder out to the temp directory to hold until the end of the run
    # Delete the folder to remove the old files.
    $tempLocation = Join-Path -Path $env:Temp -ChildPath $DSCModuleName
    Copy-Item -Path $moduleRoot -Destination $tempLocation -Recurse -Force
    Remove-Item -Path $moduleRoot -Recurse -Force
    $null = New-Item -Path $moduleRoot -ItemType Directory
}


# Copy the module to be tested into the Module Root
Copy-Item -Path $PSScriptRoot\..\..\* -Destination $moduleRoot -Recurse -Force -Exclude '.git'

# Import the Module
$Splat = @{
    Path = $moduleRoot
    ChildPath = $RelativeModulePath
    Resolve = $true
    ErrorAction = 'Stop'
}
$DSCModuleFile = Get-Item -Path (Join-Path @Splat)

# Remove all copies of the module from memory so an old one is not used.
if (Get-Module -Name $DSCModuleFile.BaseName -All)
{
    Get-Module -Name $DSCModuleFile.BaseName -All | Remove-Module
}

# Import the Module to test.
Import-Module -Name $DSCModuleFile.FullName -Force

<#
  This is to fix a problem in AppVoyer where we have multiple copies of the resource
  in two different folders. This should probably be adjusted to be smarter about how
  it finds the resources.
#>
if (($env:PSModulePath).Split(';') -ccontains $pwd.Path)
{
    $script:tempPath = $env:PSModulePath
    $env:PSModulePath = ($env:PSModulePath -split ';' | Where-Object {$_ -ne $pwd.path}) -join ';'
}

# Preserve and set the execution policy so that the DSC MOF can be created
$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -ne 'Unrestricted')
{
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
    $rollbackExecution = $true
}
#endregion

# Using try/finally to always cleanup even if something awful happens.
try
{
    #region Integration Tests
    <#
      This file exists so we can load the test file without necessarily having xNetworking in
      the $env:PSModulePath. Otherwise PowerShell will throw an error when reading the Pester File.
    #>
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$DSCResourceName.config.ps1"
    . $ConfigFile

    Describe "$($DSCResourceName)_Integration" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                [System.Environment]::SetEnvironmentVariable('PSModulePath',
                    $env:PSModulePath,[System.EnvironmentVariableTarget]::Machine)
                Invoke-Expression -Command "$($DSCResourceName)_Config -OutputPath `$WorkingFolder"
                Start-DscConfiguration -Path (Join-Path -Path $env:Temp -ChildPath $DSCResourceName) `
                    -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object {$_.ConfigurationName -eq 'MSFT_xNetconnectionProfile_Config'}
            $rule.InterfaceAlias   | Should Be $current.InterfaceAlias
            $rule.NetworkCategory  | Should Be $current.NetworkCategory
            $rule.IPv4Connectivity | Should Be $current.IPv4Connectivity
            $rule.IPv6Connectivity | Should Be $current.IPv6Connectivity
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    # Set PSModulePath back to previous settings
    $env:PSModulePath = $script:tempPath;

    # Restore the Execution Policy
    if ($rollbackExecution)
    {
        Set-ExecutionPolicy -ExecutionPolicy $executionPolicy -Force
    }

    # Cleanup Working Folder
    if (Test-Path -Path $WorkingFolder)
    {
        Remove-Item -Path $WorkingFolder -Recurse -Force
    }

    # Clean up after the test completes.
    Remove-Item -Path $moduleRoot -Recurse -Force

    # Restore previous versions, if it exists.
    if ($tempLocation)
    {
        $null = New-Item -Path $moduleRoot -ItemType Directory
        Copy-Item -Path $tempLocation -Destination "${env:ProgramFiles}\WindowsPowerShell\Modules" -Recurse -Force
        Remove-Item -Path $tempLocation -Recurse -Force
    }
    #endregion

    # TODO: Other Cleanup Code Goes Here...
}
