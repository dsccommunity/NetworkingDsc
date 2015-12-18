<#
  This file exists so we can load the test file without necessarily having xNetworking in
  the $env:PSModulePath. Otherwise PowerShell will throw an error when reading the Pester File
#>

$rule = @{
    # TODO: Populate $rule with config data.
}

# TODO: Modify ResourceName
configuration 'MSFT_<xResourceName>' {
    Import-DscResource -ModuleName xNetworking
    node localhost {
       # TODO: Modify ResourceName
       '<xResourceName>' Integration_Test {
            # TODO: Fill Configuration Code Here
       }
    }
}

# TODO: (Optional): Add More Configuration Templates
