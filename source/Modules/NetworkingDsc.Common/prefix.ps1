$script:dscResourceCommonModulePath = Join-Path -Path $PSScriptRoot -ChildPath '../DscResource.Common'

Import-Module -Name $script:dscResourceCommonModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'
