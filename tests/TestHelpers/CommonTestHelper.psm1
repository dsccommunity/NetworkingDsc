<#
    .SYNOPSIS
        Determines if Network Team integration tests can be executed.

    .PARAMETER NetworkAdapters
        The network adapters that should be used for integration testing.
#>
function Test-NetworkTeamIntegrationEnvironment
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [System.String[]]
        $NetworkAdapters
    )

    $executeTests = $true

    if ($env:APPVEYOR -eq $true)
    {
        Write-Warning -Message 'Performing Network Teaming integration tests on AppVeyor is not possible.'
        $executeTests = $false
    }

    if ($NetworkAdapters.Count -lt 2)
    {
        Write-Warning -Message (@(
                'Performing Network Teaming integration tests requires at least two compatible'
                'network adapters to be specified.'
                'Please see the comment based help in the header of the integration tests for'
                'instruction on how to specify the network adapters to use.'
            ) -join ' ')
        $executeTests = $false
    }

    foreach ($NetworkAdapter in $NetworkAdapters)
    {
        $adapter = Get-NetAdapter -Name $NetworkAdapter -ErrorAction SilentlyContinue
        if (-not $adapter)
        {
            Write-Warning -Message ('Network Teaming integration test adapter ''{0}'' could not be found.' -f $NetworkAdapter)
            $executeTests = $false
        }
    }

    return $executeTests
}

<#
    .SYNOPSIS
        Create a loopback adapter for use in integration testing.

    .PARAMETER AdapterName
        The name of the loopback adapter to create.
#>
function New-IntegrationLoopbackAdapter
{
    [cmdletbinding()]
    param
    (
        [Parameter()]
        [System.String]
        $AdapterName
    )

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

<#
    .SYNOPSIS
        Remove a loopback adapter that was created for use in integration testing.

    .PARAMETER AdapterName
        The name of the loopback adapter to remove.
#>
function Remove-IntegrationLoopbackAdapter
{
    [cmdletbinding()]
    param
    (
        [Parameter()]
        [System.String]
        $AdapterName
    )

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
        -Force

} # function Remove-IntegrationLoopbackAdapter

Export-ModuleMember -Function `
    Test-NetworkTeamIntegrationEnvironment, `
    New-IntegrationLoopbackAdapter, `
    Remove-IntegrationLoopbackAdapter
