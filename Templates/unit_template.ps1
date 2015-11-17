<#
.Synopsis
   Template for creating Unit Tests
.DESCRIPTION
   To Use:
     1. Copy to \Tests\Integration\ folder and rename MSFT_x<ResourceName>.tests.ps1
     2. Customize TODO sections.
     3. Create MSFT_x<ResourceName>.config.ps1 to be used as test DSC Configurtion file.

.NOTES
   Code in HEADER and FOOTER regions are standard and may be moved into DSCResource.Tools in
   Future and therefore should not be altered if possible.
#>


# TODO: Customize these paramters...
$DSCModuleName      = 'xNetworking'
$DSCResourceName    = 'MSFT_x<ResourceName>'
$RelativeModulePath = "DSCResources\$DSCResourceName\$DSCResourceName.psm1"
# /TODO

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

# TODO: Other Optional Init Code Goes Here...

# Begin Testing
try
{

    #region Pester Tests

    InModuleScope $DSCResourceName {

        #region Pester Test Initialization
        # TODO: Optopnal Load Mock for use in Pester tests here...
        #endregion


        #region Function Get-TargetResource
        Describe 'Get-TargetResource' {
            # TODO: Complete Tests...
        }
        #endregion


        #region Function Test-TargetResource
        Describe 'Test-TargetResource' {
            # TODO: Complete Tests...
        }
        #endregion


        #region Function Set-TargetResource
        Describe 'Set-TargetResource' {
            # TODO: Complete Tests...
        }
        #endregion

        # TODO: Pester Tests for any Helper Cmdlets

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

    # TODO: Other Optional Cleanup Code Goes Here...
}
