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
$localizedData = Get-LocalizedData `
    -ResourceName 'MSFT_xDNSServerAddress' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
    Returns the current DNS Server Addresses for an interface.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the DNS server address is set.

    .PARAMETER AddressFamily
    IP address family.

    .PARAMETER Address
    The desired DNS Server address(es). Exclude to enable DHCP.
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
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Address
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.GettingDNSServerAddressesMessage)
        ) -join '')

    # Remove the parameters we don't want to splat
    $null = $PSBoundParameters.Remove('Address')

    # Get the current DNS Server Addresses based on the parameters given.
    [String[]] $currentAddress = Get-DnsClientServerStaticAddress `
        @PSBoundParameters `
        -ErrorAction Stop

    $returnValue = @{
        Address        = $currentAddress
        AddressFamily  = $AddressFamily
        InterfaceAlias = $InterfaceAlias
    }

    return $returnValue
}

<#
    .SYNOPSIS
    Sets the DNS Server Address for an interface.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the DNS server address is set.

    .PARAMETER AddressFamily
    IP address family.

    .PARAMETER Address
    The desired DNS Server address(es). Exclude to enable DHCP.

    .PARAMETER Validate
    Requires that the DNS Server addresses be validated if they are updated.
    It will cause the resource to throw a 'A general error occurred that is not covered by a more
    specific error code.' error if set to True and specified DNS Servers are not accessible.
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
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Address,

        [Parameter()]
        [Boolean]
        $Validate = $false
    )

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
        $($LocalizedData.ApplyingDNSServerAddressesMessage)
        ) -join '')

    # If address not passed, set to an empty array
    if (-not $PSBoundParameters.ContainsKey('Address'))
    {
        [String[]] $Address = @()
    }

    # Remove the parameters we don't want to splat
    $null = $PSBoundParameters.Remove('Address')
    $null = $PSBoundParameters.Remove('Validate')

    # Get the current DNS Server Addresses based on the parameters given.
    [String[]] $currentAddress = @(Get-DnsClientServerStaticAddress `
        @PSBoundParameters `
        -ErrorAction Stop)

    # Check if the Server addresses are the same as the desired addresses.
    [Boolean] $addressDifferent = (@(Compare-Object `
            -ReferenceObject $currentAddress `
            -DifferenceObject $Address `
            -SyncWindow 0).Length -gt 0)

    if ($addressDifferent)
    {
        $dnsServerAddressSplat = @{
            InterfaceAlias = $InterfaceAlias
        }

        if ($Address.Count -eq 0)
        {
            # Reset the DNS server address to DHCP
            $dnsServerAddressSplat += @{
                ResetServerAddresses = $true
            }

            Set-DnsClientServerAddress @dnsServerAddressSplat `
                -ErrorAction Stop

            Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($LocalizedData.DNSServersHaveBeenSetToDHCPMessage)
                ) -join '' )
        }
        else
        {
            # Set the DNS server address to static
            $dnsServerAddressSplat += @{
                Address  = $Address
                Validate = $Validate
            }

            Set-DnsClientServerAddress @dnsServerAddressSplat `
                -ErrorAction Stop

            Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($LocalizedData.DNSServersHaveBeenSetCorrectlyMessage)
                ) -join '' )
        }
    }
    else
    {
        # Test will return true in this case
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.DNSServersAlreadySetMessage)
            ) -join '' )
    }
}

<#
    .SYNOPSIS
    Tests the current state of a DNS Server Address for an interface.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the DNS server address is set.

    .PARAMETER AddressFamily
    IP address family.

    .PARAMETER Address
    The desired DNS Server address(es). Exclude to enable DHCP.

    .PARAMETER Validate
    Requires that the DNS Server addresses be validated if they are updated.
    It will cause the resource to throw a 'A general error occurred that is not covered by a more
    specific error code.' error if set to True and specified DNS Servers are not accessible.
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
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Address,

        [Parameter()]
        [Boolean]
        $Validate = $false
    )
    # Flag to signal whether settings are correct
    [Boolean] $desiredConfigurationMatch = $true

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.CheckingDNSServerAddressesMessage)
        ) -join '' )

    # Validate the Address passed or set to empty array if not passed
    if ($PSBoundParameters.ContainsKey('Address'))
    {
        foreach ($ServerAddress in $Address)
        {
            Assert-ResourceProperty `
                -Address $ServerAddress `
                -AddressFamily $AddressFamily `
                -InterfaceAlias $InterfaceAlias
        } # foreach
    }
    else
    {
        [String[]] $Address = @()
    } # if

    # Remove the parameters we don't want to splat
    $null = $PSBoundParameters.Remove('Address')
    $null = $PSBoundParameters.Remove('Validate')

    # Get the current DNS Server Addresses based on the parameters given.
    [String[]] $currentAddress = @(Get-DnsClientServerStaticAddress `
        @PSBoundParameters `
        -ErrorAction Stop)

    # Check if the Server addresses are the same as the desired addresses.
    [Boolean] $addressDifferent = (@(Compare-Object `
            -ReferenceObject $currentAddress `
            -DifferenceObject $Address `
            -SyncWindow 0).Length -gt 0)

    if ($addressDifferent)
    {
        $desiredConfigurationMatch = $false

        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.DNSServersNotCorrectMessage) `
                -f ($Address -join ','),($currentAddress -join ',')
            ) -join '' )
    }
    else
    {
        # Test will return true in this case
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.DNSServersSetCorrectlyMessage)
            ) -join '' )
    }
    return $desiredConfigurationMatch
}

<#
    .SYNOPSIS
    Checks the Address details are valid and do not conflict with Address family.
    Ensures interface exists. If any problems are detected an exception will be thrown.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the DNS server address is set.

    .PARAMETER AddressFamily
    IP address family.

    .PARAMETER Address
    The desired DNS Server address. Set to empty to enable DHCP.
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

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [String]
        $AddressFamily,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Address
    )

    if ( -not (Get-NetAdapter | Where-Object -Property Name -EQ $InterfaceAlias ))
    {
        New-InvalidArgumentException `
            -Message ($LocalizedData.InterfaceNotAvailableError -f $InterfaceAlias) `
            -ArgumentName 'InterfaceAlias'
    }

    if ( -not ([System.Net.IPAddress]::TryParse($Address, [ref]0)))
    {
        New-InvalidArgumentException `
            -Message ($LocalizedData.AddressFormatError -f $Address) `
            -ArgumentName 'Address'
    }

    $detectedAddressFamily = ([System.Net.IPAddress]$Address).AddressFamily.ToString()
    if (($detectedAddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork.ToString()) `
        -and ($AddressFamily -ne 'IPv4'))
    {
        New-InvalidArgumentException `
            -Message ($LocalizedData.AddressIPv4MismatchError -f $Address,$AddressFamily) `
            -ArgumentName 'Address'
    }

    if (($detectedAddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6.ToString()) `
        -and ($AddressFamily -ne 'IPv6'))
    {
        New-InvalidArgumentException `
            -Message ($LocalizedData.AddressIPv6MismatchError -f $Address,$AddressFamily) `
            -ArgumentName 'Address'
    }
} # Assert-ResourceProperty

Export-ModuleMember -function *-TargetResource
