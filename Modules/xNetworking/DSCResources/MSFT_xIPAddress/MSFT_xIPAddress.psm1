$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Networking Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'NetworkingDsc.Common' `
            -ChildPath 'NetworkingDsc.Common.psm1'))

# Import the Networking Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'NetworkingDsc.ResourceHelper' `
            -ChildPath 'NetworkingDsc.ResourceHelper.psm1'))

# Import Localization Strings
$localizedDataSplat = @{
    ResourceName = 'MSFT_xIPAddress'
    ResourcePath = (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)
}
$localizedData = Get-LocalizedData @localizedDataSplat

<#
    .SYNOPSIS
    Returns the current state of an IP address assigned to an interface.

    .PARAMETER IPAddress
    The desired IP address.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the IP address should be set.

    .PARAMETER AddressFamily
    IP address family.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [System.String]
        $AddressFamily = 'IPv4'
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.GettingIPAddressMessage)
        ) -join '')

    $getNetIPAddressParameters = @{
        InterfaceAlias = $InterfaceAlias
        AddressFamily  = $AddressFamily
    }

    $currentIPAddress = Get-NetIPAddress @getNetIPAddressParameters

    $currentIPAddressWithPrefix = $currentIPAddress |
        Foreach-Object {
            "$($_.IPAddress)/$($_.prefixLength)"
        }

    $returnValue = @{
        IPAddress      = @($currentIPAddressWithPrefix)
        AddressFamily  = $AddressFamily
        InterfaceAlias = $InterfaceAlias
    }

    return $returnValue
}

<#
    .SYNOPSIS
    Sets an IP address on an interface.

    .PARAMETER IPAddress
    The desired IP address.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the IP address should be set.

    .PARAMETER AddressFamily
    IP address family.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [System.String]
        $AddressFamily = 'IPv4'
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.ApplyingIPAddressMessage)
        ) -join '')

    # Use $AddressFamily to select the IPv4 or IPv6 destination prefix
    $destinationPrefix = '0.0.0.0/0'

    if ($AddressFamily -eq 'IPv6')
    {
        $destinationPrefix = '::/0'
        $prefixLength = 64
    }

    # Get all the default routes - this has to be done in case the IP Address is being Removed
    $getNetRouteParameters = @{
        InterfaceAlias = $InterfaceAlias
        AddressFamily  = $AddressFamily
        ErrorAction    = 'Stop'
    }

    $defaultRoutes = @(Get-NetRoute @getNetRouteParameters).Where(
        {
            $_.DestinationPrefix -eq $destinationPrefix
        }
    )

    <#
        Remove any default routes on the specified interface -- it is important to do
        this *before* removing the IP address, particularly in the case where the IP
        address was auto-configured by DHCP
    #>
    if ($defaultRoutes)
    {
        foreach ($defaultRoute in $defaultRoutes)
        {
            $removeNetRouteParameters = @{
                DestinationPrefix = $defaultRoute.DestinationPrefix
                NextHop           = $defaultRoute.NextHop
                InterfaceIndex    = $defaultRoute.InterfaceIndex
                AddressFamily     = $defaultRoute.AddressFamily
                Confirm           = $false
                ErrorAction       = 'Stop'
            }
            Remove-NetRoute @removeNetRouteParameters
        }
    }

    # Get the current IP Address based on the parameters given.
    $getNetIPAddressParameters = @{
        InterfaceAlias = $InterfaceAlias
        AddressFamily  = $AddressFamily
        ErrorAction    = 'Stop'
    }

    $currentIPs = @(Get-NetIPAddress @getNetIPAddressParameters)

    # Remove any IP addresses on the specified interface
    if ($currentIPs)
    {
        foreach ($currentIP in $currentIPs)
        {
            $removeIP = $false

            if ($currentIP.IPAddress -notin ($IPAddress -replace '\/\S*', ''))
            {
                $removeIP = $true
            }
            elseif ($currentIP.IPAddress -in ($IPAddress -replace '\/\S*', ''))
            {
                $existingIP = $IPAddress | Where-Object {
                    $_ -match $currentIP.IPAddress
                }

                if ($existingIP -ne "$($currentIP.IPAddress)/$($currentIP.prefixLength)")
                {
                    $removeIP = $true
                }
            }

            if ($removeIP)
            {
                $removeNetIPAddressParameters = @{
                    IPAddress      = $currentIP.IPAddress
                    InterfaceIndex = $currentIP.InterfaceIndex
                    AddressFamily  = $currentIP.AddressFamily
                    prefixLength   = $currentIP.prefixLength
                    Confirm        = $false
                    ErrorAction    = 'Stop'
                }

                Remove-NetIPAddress @removeNetIPAddressParameters
            }
        }
    }

    $ipAddressObject = Get-IPAddressPrefix -IPAddress $IPAddress -AddressFamily $AddressFamily

    foreach ($singleIP in $ipAddressObject)
    {
        $prefixLength = $singleIP.prefixLength

        # Build parameter hash table
        $newNetIPAddressParameters = @{
            IPAddress      = $singleIP.IPAddress
            prefixLength   = $prefixLength
            InterfaceAlias = $InterfaceAlias
        }

        # Apply the specified IP configuration
        $null = New-NetIPAddress @newNetIPAddressParameters -ErrorAction Stop

        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                $($LocalizedData.IPAddressSetStateMessage)
            ) -join '' )
    }
} # Set-TargetResource

<#
    .SYNOPSIS
    Tests the IP address on the interface.

    .PARAMETER IPAddress
    The desired IP address.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the IP address should be set.

    .PARAMETER AddressFamily
    IP address family.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [System.String]
        $AddressFamily = 'IPv4'
    )

    # Flag to signal whether settings are correct
    [System.Boolean] $desiredConfigurationMatch = $true

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($LocalizedData.CheckingIPAddressMessage)
        ) -join '')

    Assert-ResourceProperty @PSBoundParameters

    <#
        Get the current IP Address based on the parameters given.
        First make sure that adapter is available
    #>
    [System.Boolean] $adapterBindingReady = $false
    [System.DateTime] $startTime = Get-Date

    while (-not $adapterBindingReady -and (((Get-Date) - $startTime).TotalSeconds) -lt 30)
    {
        $getNetIPAddressParameters = @{
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = $AddressFamily
            ErrorAction    = 'SilentlyContinue'
        }

        $currentIPs = @(Get-NetIPAddress @getNetIPAddressParameters)

        if ($currentIPs)
        {
            $adapterBindingReady = $true
        }
        else
        {
            Start-Sleep -Milliseconds 200
        }
    } # while

    $ipAddressObject = Get-IPAddressPrefix -IPAddress $IPAddress -AddressFamily $AddressFamily

    # Test if the IP Address passed is present
    foreach ($singleIP in $ipAddressObject)
    {
        $prefixLength = $singleIP.prefixLength

        if ($singleIP.IPAddress -notin $currentIPs.IPAddress)
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.IPAddressDoesNotMatchMessage) -f $singleIP, $currentIPs.IPAddress
                ) -join '' )

            $desiredConfigurationMatch = $false
        }
        else
        {
            Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                    $($LocalizedData.IPAddressMatchMessage)
                ) -join '')

            # Filter the IP addresses for the IP address to check
            $filterIP = $currentIPs.Where(
                {
                    $_.IPAddress -eq $singleIP.IPAddress
                }
            )

            # Only test the Prefix Length if the IP address is present
            if (-not $filterIP.prefixLength.Equals([System.Byte] $prefixLength))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.prefixLengthDoesNotMatchMessage) -f $prefixLength, $currentIPs.prefixLength
                    ) -join '' )

                $desiredConfigurationMatch = $false
            }
            else
            {
                Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                        $($LocalizedData.prefixLengthMatchMessage)
                    ) -join '' )
            }
        }
    }
    return $desiredConfigurationMatch
} # Test-TargetResource

<#
    .SYNOPSIS
    Check the IP Address details are valid and do not conflict with Address family.
    Also checks the prefix length and ensures the interface exists.
    If any problems are detected an exception will be thrown.

    .PARAMETER IPAddress
    The desired IP address.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the IP address should be set.

    .PARAMETER AddressFamily
    IP address family.
#>
function Assert-ResourceProperty
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InterfaceAlias,

        [Parameter()]
        [ValidateSet('IPv4', 'IPv6')]
        [System.String]
        $AddressFamily = 'IPv4'
    )

    $prefixLengthArray = ($IPAddress -split '/')[1]

    if ($prefixLengthArray.Count -ne $IPAddress.Count)
    {
        # Return the prefix length of each IP address specified
        $prefixLengthArray = $IPAddress | Foreach-Object {
            if ($_ -match '\/\d{1,3}')
            {
                ($_ -split '/')[1]
            }
            else
            {
                if ($_.split('.')[0] -in (0..127))
                {
                    $prefixLength = 8
                }
                elseif ($_.split('.')[0] -in (128..191))
                {
                    $prefixLength = 16
                }
                elseif ($_.split('.')[0] -in (192..223))
                {
                    $prefixLength = 24
                }
                if ($AddressFamily -eq 'IPv6')
                {
                    $prefixLength = 64
                }
                $prefixLength
            }
        }
    }

    if (-not (Get-NetAdapter | Where-Object -Property Name -EQ $InterfaceAlias ))
    {
        New-InvalidArgumentException `
            -Message $($($LocalizedData.InterfaceNotAvailableError) -f $InterfaceAlias) `
            -ArgumentName 'InterfaceAlias'
    }

    foreach ($singleIPAddress in $IPAddress)
    {
        $singleIP = ($singleIPAddress -split '/')[0]

        if (-not ([System.Net.Ipaddress]::TryParse($singleIP, [ref]0)))
        {
            New-InvalidArgumentException `
                -Message $($($LocalizedData.AddressFormatError) -f $singleIPAddress) `
                -ArgumentName 'IPAddress'
        }

        $detectedAddressFamily = ([System.Net.IPAddress]$singleIP).AddressFamily.ToString()

        if (($detectedAddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork.ToString()) `
                -and ($AddressFamily -ne 'IPv4'))
        {
            New-InvalidArgumentException `
                -Message $($($LocalizedData.AddressIPv4MismatchError) -f $singleIPAddress, $AddressFamily) `
                -ArgumentName 'IPAddress'
        }

        if (($detectedAddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6.ToString()) `
                -and ($AddressFamily -ne 'IPv6'))
        {
            New-InvalidArgumentException `
                -Message $($($LocalizedData.AddressIPv6MismatchError) -f $singleIPAddress, $AddressFamily) `
                -ArgumentName 'IPAddress'
        }
    }

    foreach ($prefixLength in $prefixLengthArray)
    {
        $prefixLength = [uint32]::Parse($prefixLength)

        if ((
                ($AddressFamily -eq 'IPv4') `
                    -and (($prefixLength -lt [uint32]0) -or ($prefixLength -gt [uint32]32))
            ) -or (
                ($AddressFamily -eq 'IPv6') `
                    -and (($prefixLength -lt [uint32]0) -or ($prefixLength -gt [uint32]128))
            ))
        {
            New-InvalidArgumentException `
                -Message $($($LocalizedData.PrefixLengthError) -f $prefixLength, $AddressFamily) `
                -ArgumentName 'IPAddress'
        }
    }
} # Assert-ResourceProperty

Export-ModuleMember -function *-TargetResource
