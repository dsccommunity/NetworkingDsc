<#
    .SYNOPSIS
        This function will find a network adapter based on the provided
        search parameters.

    .PARAMETER Name
        This is the name of network adapter to find.

    .PARAMETER PhysicalMediaType
        This is the media type of the network adapter to find.

    .PARAMETER Status
        This is the status of the network adapter to find.

    .PARAMETER MacAddress
        This is the MAC address of the network adapter to find.

    .PARAMETER InterfaceDescription
        This is the interface description of the network adapter to find.

    .PARAMETER InterfaceIndex
        This is the interface index of the network adapter to find.

    .PARAMETER InterfaceGuid
        This is the interface GUID of the network adapter to find.

    .PARAMETER DriverDescription
        This is the driver description of the network adapter.

    .PARAMETER InterfaceNumber
        This is the interface number of the network adapter if more than one
        are returned by the parameters.

    .PARAMETER IgnoreMultipleMatchingAdapters
        This switch will suppress an error occurring if more than one matching
        adapter matches the parameters passed.
#>
function Find-NetworkAdapter
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $PhysicalMediaType,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Up', 'Disconnected', 'Disabled')]
        [System.String]
        $Status = 'Up',

        [Parameter()]
        [System.String]
        $MacAddress,

        [Parameter()]
        [System.String]
        $InterfaceDescription,

        [Parameter()]
        [System.UInt32]
        $InterfaceIndex,

        [Parameter()]
        [System.String]
        $InterfaceGuid,

        [Parameter()]
        [System.String]
        $DriverDescription,

        [Parameter()]
        [System.UInt32]
        $InterfaceNumber = 1,

        [Parameter()]
        [System.Boolean]
        $IgnoreMultipleMatchingAdapters = $false
    )

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($script:localizedData.FindingNetAdapterMessage)
        ) -join '')

    $adapterFilters = @()

    if ($PSBoundParameters.ContainsKey('Name'))
    {
        $adapterFilters += @('($_.Name -eq $Name)')
    } # if

    if ($PSBoundParameters.ContainsKey('PhysicalMediaType'))
    {
        $adapterFilters += @('($_.PhysicalMediaType -eq $PhysicalMediaType)')
    } # if

    if ($PSBoundParameters.ContainsKey('Status'))
    {
        $adapterFilters += @('($_.Status -eq $Status)')
    } # if

    if ($PSBoundParameters.ContainsKey('MacAddress'))
    {
        $adapterFilters += @('($_.MacAddress -eq $MacAddress)')
    } # if

    if ($PSBoundParameters.ContainsKey('InterfaceDescription'))
    {
        $adapterFilters += @('($_.InterfaceDescription -eq $InterfaceDescription)')
    } # if

    if ($PSBoundParameters.ContainsKey('InterfaceIndex'))
    {
        $adapterFilters += @('($_.InterfaceIndex -eq $InterfaceIndex)')
    } # if

    if ($PSBoundParameters.ContainsKey('InterfaceGuid'))
    {
        $adapterFilters += @('($_.InterfaceGuid -eq $InterfaceGuid)')
    } # if

    if ($PSBoundParameters.ContainsKey('DriverDescription'))
    {
        $adapterFilters += @('($_.DriverDescription -eq $DriverDescription)')
    } # if

    if ($adapterFilters.Count -eq 0)
    {
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                $($script:localizedData.AllNetAdaptersFoundMessage)
            ) -join '')

        $matchingAdapters = @(Get-NetAdapter)
    }
    else
    {
        # Join all the filters together
        $adapterFilterScript = '(' + ($adapterFilters -join ' -and ') + ')'
        $matchingAdapters = @(Get-NetAdapter |
            Where-Object -FilterScript ([ScriptBlock]::Create($adapterFilterScript)))
    }

    # Were any adapters found matching the criteria?
    if ($matchingAdapters.Count -eq 0)
    {
        New-InvalidOperationException `
            -Message ($script:localizedData.NetAdapterNotFoundError)

        # Return a null so that ErrorAction SilentlyContinue works correctly
        return $null
    }
    else
    {
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                $($script:localizedData.NetAdapterFoundMessage -f $matchingAdapters.Count)
            ) -join '')

        if ($matchingAdapters.Count -gt 1)
        {
            if ($IgnoreMultipleMatchingAdapters)
            {
                # Was the number of matching adapters found matching the adapter number?
                if (($InterfaceNumber -gt 1) -and ($InterfaceNumber -gt $matchingAdapters.Count))
                {
                    New-InvalidOperationException `
                        -Message ($script:localizedData.InvalidNetAdapterNumberError `
                            -f $matchingAdapters.Count, $InterfaceNumber)

                    # Return a null so that ErrorAction SilentlyContinue works correctly
                    return $null
                } # if
            }
            else
            {
                New-InvalidOperationException `
                    -Message ($script:localizedData.MultipleMatchingNetAdapterFound `
                        -f $matchingAdapters.Count)

                # Return a null so that ErrorAction SilentlyContinue works correctly
                return $null
            } # if
        } # if
    } # if

    # Identify the exact adapter from the adapters that match
    $exactAdapter = $matchingAdapters[$InterfaceNumber - 1]

    $returnValue = [PSCustomObject] @{
        Name                 = $exactAdapter.Name
        PhysicalMediaType    = $exactAdapter.PhysicalMediaType
        Status               = $exactAdapter.Status
        MacAddress           = $exactAdapter.MacAddress
        InterfaceDescription = $exactAdapter.InterfaceDescription
        InterfaceIndex       = $exactAdapter.InterfaceIndex
        InterfaceGuid        = $exactAdapter.InterfaceGuid
        MatchingAdapterCount = $matchingAdapters.Count
    }

    return $returnValue
}
