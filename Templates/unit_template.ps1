# Template for Unit Testing

# +++ Customize these paramters...
$DSCModuleName   = 'xNetworking'
$DSCResourceName = 'MSFT_x<ResourceName>'
$RelativeModulePath = "DSCResources\$DSCResourceName\$DSCResourceName.psm1"

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

# +++ Other Init Code Goes Here...

# Begin Testing
try
{

####################################################################################################

    InModuleScope $DSCResourceName {

####################################################################################################

        # +++ Load Mock Data Here...

####################################################################################################

        Describe 'Get-TargetResource' {
        }

####################################################################################################

        Describe 'Test-TargetResource' {
        }

####################################################################################################

        Describe 'Set-TargetResource' {
        }

####################################################################################################

    }

####################################################################################################
}
finally
{
    # Set PSModulePath back to previous settings
    $env:PSModulePath = $script:tempPath;

    # Restore the Execution Policy
    if ($rollbackExecution)
    {
        Set-ExecutionPolicy -ExecutionPolicy $executionPolicy -Force
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

    # +++ Other Cleanup Code Goes Here...
}
