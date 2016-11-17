function New-IntegrationLoopbackAdapter
{
    [cmdletbinding()]
    param (
        [String]
        $AdapterName
    )
    # Configure Loopback Adapter
    if ($env:APPVEYOR) {
        # Running in AppVeyor so force silent install of LoopbackAdapter
        $Splat = @{ Force = $true }
    }
    else
    {
        $Splat = @{ Force = $false }
    } # if

    $loopbackAdapterModuleName = 'LoopbackAdapter'
    $loopbackAdapterModulePath = "$env:userProfile\Documents\WindowsPowerShell\Modules\$LoopbackAdapterModuleName"

    $loopbackAdapterModule = Get-Module -Name $loopbackAdapterModuleName -ListAvailable

    if ($null -eq $loopbackAdapterModule)
    {
        Install-ModuleFromPowerShellGallery `
            -ModuleName $LoopbackAdapterModuleName `
            -DestinationPath $LoopbackAdapterModulePath
            
         $loopbackAdapterModule = Get-Module -Name $loopbackAdapterModuleName -ListAvailable
    }
    
    if ($loopbackAdapterModule) {
        # Import the module if it is available
        $loopbackAdapterModule | Import-Module -Force
    }
    else
    {
        # Module could not/would not be installed - so warn user that tests will fail.
        throw 'LoopbackAdapter Module could not be installed.'
    } # if

    try
    {
        # Does the loopback adapter already exist?
        $null = Get-LoopbackAdapter `
            -Name $AdapterName
    }
    catch
    {
        # The loopback Adapter does not exist so create it
        $null = New-LoopbackAdapter `
            -Name $AdapterName `
            -ErrorAction Stop `
            @Splat
    } # try
} # function New-IntegrationLoopbackAdapter

function Remove-IntegrationLoopbackAdapter
{
    [cmdletbinding()]
    param (
        [String]
        $AdapterName
    )
    if ($env:APPVEYOR) {
        # Running in AppVeyor so force silent install of LoopbackAdapter
        $Splat = @{ Force = $true }
    }
    else
    {
        $Splat = @{ Force = $false }
    }

    try
    {
        # Does the loopback adapter exist?
        $null = Get-LoopbackAdapter `
            -Name $AdapterName
    }
    catch
    {
        # Loopback Adapter does not exist - do nothing
        return
    }

    # Remove Loopback Adapter
    Remove-LoopbackAdapter `
        -Name $AdapterName `
        @Splat

} # function Remove-IntegrationLoopbackAdapter
