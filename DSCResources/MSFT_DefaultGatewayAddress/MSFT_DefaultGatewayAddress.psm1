$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Networking Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'NetworkingDsc.Common' `
            -ChildPath 'NetworkingDsc.Common.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_DefaultGatewayAddress'

<#
    .SYNOPSIS
    Returns the current state of the Default Gateway for an interface.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the default gateway address is set.

    .PARAMETER AddressFamily
    IP address family.

    .PARAMETER Address
    The desired default gateway address - if not provided default gateway will be removed.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [String]
        $AddressFamily,

        [Parameter()]
        [String]
        $Address
    )

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($script:localizedData.GettingDefaultGatewayAddressMessage)
        ) -join '' )

    # Use $AddressFamily to select the IPv4 or IPv6 destination prefix
    $destinationPrefix = '0.0.0.0/0'
    if ($AddressFamily -eq 'IPv6')
    {
        $destinationPrefix = '::/0'
    }
    # Get all the default routes
    $defaultRoutes = Get-NetRoute -InterfaceAlias $InterfaceAlias -AddressFamily `
        $AddressFamily -ErrorAction Stop | `
        Where-Object { $_.DestinationPrefix -eq $destinationPrefix }

    $returnValue = @{
        AddressFamily  = $AddressFamily
        InterfaceAlias = $InterfaceAlias
    }
    # If there is a Default Gateway defined for this interface/address family add it
    # to the return value.
    if ($defaultRoutes)
    {
        $returnValue += @{ Address = $defaultRoutes.NextHop }
    }
    else
    {
        $returnValue += @{ Address = $null }
    }

    $returnValue
}

<#
    .SYNOPSIS
    Sets the Default Gateway for an interface.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the default gateway address is set.

    .PARAMETER AddressFamily
    IP address family.

    .PARAMETER Address
    The desired default gateway address - if not provided default gateway will be removed.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [String]
        $AddressFamily,

        [Parameter()]
        [String]
        $Address
    )

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($script:localizedData.ApplyingDefaultGatewayAddressMessage)
        ) -join '' )

    # Use $AddressFamily to select the IPv4 or IPv6 destination prefix
    $destinationPrefix = '0.0.0.0/0'

    if ($AddressFamily -eq 'IPv6')
    {
        $destinationPrefix = '::/0'
    }

    # Get all the default routes
    $defaultRoutes = @(Get-NetRoute `
            -InterfaceAlias $InterfaceAlias `
            -AddressFamily $AddressFamily `
            -ErrorAction Stop).Where( { $_.DestinationPrefix -eq $destinationPrefix } )

    # Remove any existing default route
    foreach ($defaultRoute in $defaultRoutes)
    {
        Remove-NetRoute `
            -DestinationPrefix $defaultRoute.DestinationPrefix `
            -NextHop $defaultRoute.NextHop `
            -InterfaceIndex $defaultRoute.InterfaceIndex `
            -AddressFamily $defaultRoute.AddressFamily `
            -Confirm:$false -ErrorAction Stop
    }

    if ($Address)
    {
        # Set the correct Default Route
        # Build parameter hash table
        $parameters = @{
            DestinationPrefix = $destinationPrefix
            InterfaceAlias    = $InterfaceAlias
            AddressFamily     = $AddressFamily
            NextHop           = $Address
        }

        New-NetRoute @Parameters -ErrorAction Stop

        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                $($script:localizedData.DefaultGatewayAddressSetToDesiredStateMessage)
            ) -join '' )
    }
    else
    {
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                $($script:localizedData.DefaultGatewayRemovedMessage)
            ) -join '' )
    }
}

<#
    .SYNOPSIS
    Tests the state of the Default Gateway for an interface.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the default gateway address is set.

    .PARAMETER AddressFamily
    IP address family.

    .PARAMETER Address
    The desired default gateway address - if not provided default gateway will be removed.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [String]
        $AddressFamily,

        [Parameter()]
        [String]
        $Address
    )

    # Flag to signal whether settings are correct
    [Boolean] $desiredConfigurationMatch = $true

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($script:localizedData.CheckingDefaultGatewayAddressMessage)
        ) -join '' )

    Assert-ResourceProperty @PSBoundParameters

    # Use $AddressFamily to select the IPv4 or IPv6 destination prefix
    $destinationPrefix = '0.0.0.0/0'
    if ($AddressFamily -eq 'IPv6')
    {
        $destinationPrefix = '::/0'
    }

    # Get all the default routes
    $defaultRoutes = @(Get-NetRoute `
            -InterfaceAlias $InterfaceAlias `
            -AddressFamily $AddressFamily `
            -ErrorAction Stop).Where( { $_.DestinationPrefix -eq $destinationPrefix } )

    # Test if the Default Gateway passed is equal to the current default gateway
    if ($Address)
    {
        if ($defaultRoutes)
        {
            if (-not $defaultRoutes.Where( { $_.NextHop -eq $Address } ))
            {
                Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                        $($script:localizedData.DefaultGatewayNotMatchMessage) -f $Address, $defaultRoutes.NextHop
                    ) -join '' )
                $desiredConfigurationMatch = $false
            }
            else
            {
                Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                        $($script:localizedData.DefaultGatewayCorrectMessage)
                    ) -join '' )
            }
        }
        else
        {
            Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                    $($script:localizedData.DefaultGatewayDoesNotExistMessage) -f $Address
                ) -join '' )
            $desiredConfigurationMatch = $false
        }
    }
    else
    {
        # Is a default gateway address set?
        if ($defaultRoutes)
        {
            Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                    $($script:localizedData.DefaultGatewayExistsButShouldNotMessage)
                ) -join '' )
            $desiredConfigurationMatch = $false
        }
        else
        {
            Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                    $($script:localizedData.DefaultGatewayExistsAndShouldMessage)
                    'Default Gateway does not exist which is correct.'
                ) -join '' )
        }
    }

    return $desiredConfigurationMatch
}

<#
    .SYNOPSIS
    Check the Address details are valid and do not conflict with Address family.
    Ensures interface exists. If any problems are detected an exception will be thrown.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the default gateway address is set.

    .PARAMETER AddressFamily
    IP address family.

    .PARAMETER Address
    The desired default gateway address - if not provided default gateway will be removed.
#>
function Assert-ResourceProperty
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $InterfaceAlias,

        [Parameter()]
        [ValidateSet('IPv4', 'IPv6')]
        [String]
        $AddressFamily = 'IPv4',

        [Parameter()]
        [String]
        $Address
    )

    if (-not (Get-NetAdapter | Where-Object -Property Name -EQ $InterfaceAlias ))
    {
        New-InvalidOperationException `
            -Message ($script:localizedData.InterfaceNotAvailableError -f $InterfaceAlias)
    }

    if ($Address)
    {
        if (-not ([System.Net.IPAddress]::TryParse($Address, [ref]0)))
        {
            New-InvalidArgumentException `
                -Message ($script:localizedData.AddressFormatError -f $Address) `
                -ArgumentName 'Address'
        }

        $detectedAddressFamily = ([System.Net.IPAddress]$Address).AddressFamily.ToString()

        if (($detectedAddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork.ToString()) `
                -and ($AddressFamily -ne 'IPv4'))
        {
            New-InvalidArgumentException `
                -Message ($script:localizedData.AddressIPv4MismatchError -f $Address, $AddressFamily) `
                -ArgumentName 'AddressFamily'
        }

        if (($detectedAddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6.ToString()) `
                -and ($AddressFamily -ne 'IPv6'))
        {
            New-InvalidArgumentException `
                -Message ($script:localizedData.AddressIPv6MismatchError -f $Address, $AddressFamily) `
                -ArgumentName 'AddressFamily'
        }
    }
} # Assert-ResourceProperty

Export-ModuleMember -function *-TargetResource
