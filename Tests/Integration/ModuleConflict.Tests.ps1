$script:DSCModuleName      = 'xNetworking'
$script:ModulesToTest = @( 'xStorage','xCertificate','xComputerManagement' )
<#
    These integration tests ensure that cmdlets names are not conflicting with any other
    names that are exposed by the modules.
#>

Describe "$($script:DSCModuleName)_ModuleConflict" {
    
    foreach ($moduleToTest in $script:ModulesToTest)
    {
        It "Should not contain any conlficting cmdlet names with '$moduleToTest'" {
            {
                Install-Module -Name $moduleToTest -Force
            } | Should not throw
        }
    }
}
