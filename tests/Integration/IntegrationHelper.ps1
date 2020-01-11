function New-IntegrationLoopbackAdapter
{
    [cmdletbinding()]
    param
    (
        [Parameter()]
        [String]
        $AdapterName
    )

    # Ensure the loopback adapter module is downloaded
    $LoopbackAdapterModuleName = 'LoopbackAdapter'
    $LoopbackAdapterModulePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\$LoopbackAdapterModuleName"
    Install-ModuleFromPowerShellGallery `
        -ModuleName $LoopbackAdapterModuleName `
        -DestinationPath $LoopbackAdapterModulePath

    $LoopbackAdapterModule = Join-Path `
        -Path $LoopbackAdapterModulePath `
        -ChildPath "$($LoopbackAdapterModuleName).psm1"

    # Import the loopback adapter module
    Import-Module -Name $LoopbackAdapterModule -Force

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
            -Force `
            -ErrorAction Stop
    } # try
} # function New-IntegrationLoopbackAdapter

function Remove-IntegrationLoopbackAdapter
{
    [cmdletbinding()]
    param
    (
        [Parameter()]
        [String]
        $AdapterName
    )

    if ($env:APPVEYOR)
    {
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
