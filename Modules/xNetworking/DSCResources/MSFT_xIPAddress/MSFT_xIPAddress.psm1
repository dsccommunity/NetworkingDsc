$script:ResourceRootPath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent)

# Import the xNetworking Resource Module (to import the common modules)
Import-Module -Name (Join-Path -Path $script:ResourceRootPath -ChildPath 'xNetworking.psd1')

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

    .PARAMETER PrefixLength
    The prefix length of the IP Address.

    .PARAMETER AddressFamily
    IP address family.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [ValidateNotNullOrEmpty()]
        [String[]]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $InterfaceAlias,

        [uInt32]
        $PrefixLength = 16,

        [ValidateSet('IPv4', 'IPv6')]
        [String]
        $AddressFamily = 'IPv4'
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.GettingIPAddressMessage)
        ) -join '')

    $GetNetIPAddressSplat = @{
        InterfaceAlias = $InterfaceAlias
        AddressFamily = $AddressFamily
    }
    $CurrentIPAddress = Get-NetIPAddress @GetNetIPAddressSplat

    $returnValue = @{
        IPAddress      = @($CurrentIPAddress.IPAddress)
        PrefixLength   = [uint32]@($CurrentIPAddress.PrefixLength)[0]
        AddressFamily  = $AddressFamily
        InterfaceAlias = $InterfaceAlias
    }

    $returnValue
}

<#
    .SYNOPSIS
    Sets an IP address on an interface.

    .PARAMETER IPAddress
    The desired IP address.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the IP address should be set.

    .PARAMETER PrefixLength
    The prefix length of the IP Address.

    .PARAMETER AddressFamily
    IP address family.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateNotNullOrEmpty()]
        [String[]]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $InterfaceAlias,

        [uInt32]
        $PrefixLength,

        [ValidateSet('IPv4', 'IPv6')]
        [String]
        $AddressFamily = 'IPv4'
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.ApplyingIPAddressMessage)
        ) -join '')

    # Use $AddressFamily to select the IPv4 or IPv6 destination prefix
    $DestinationPrefix = '0.0.0.0/0'
    if ($AddressFamily -eq 'IPv6')
    {
        $DestinationPrefix = '::/0'
    }

    # Get all the default routes - this has to be done in case the IP Address is
    # being Removed
    $GetNetRouteSplat = @{
        InterfaceAlias = $InterfaceAlias
        AddressFamily = $AddressFamily
        ErrorAction = 'Stop'
    }
    $defaultRoutes = @(Get-NetRoute @GetNetRouteSplat).Where( { $_.DestinationPrefix -eq $DestinationPrefix } )

    # Remove any default routes on the specified interface -- it is important to do
    # this *before* removing the IP address, particularly in the case where the IP
    # address was auto-configured by DHCP
    if ($defaultRoutes)
    {
        foreach ($defaultRoute in $defaultRoutes) {
            $RemoveNetRouteSplat = @{
                DestinationPrefix = $defaultRoute.DestinationPrefix
                NextHop = $defaultRoute.NextHop
                InterfaceIndex = $defaultRoute.InterfaceIndex
                AddressFamily = $defaultRoute.AddressFamily
                Confirm = $false
                ErrorAction = 'Stop'
            }
            Remove-NetRoute @RemoveNetRouteSplat
        }
    }

    # Get the current IP Address based on the parameters given.
    $GetNetIPAddressSplat = @{
        InterfaceAlias = $InterfaceAlias
        AddressFamily = $AddressFamily
        ErrorAction = 'Stop'
    }
    $currentIPs = @(Get-NetIPAddress @GetNetIPAddressSplat)

    # Remove any IP addresses on the specified interface
    if ($currentIPs)
    {
        foreach ($CurrentIP in $CurrentIPs) {
            if ($CurrentIP -notin $IPAddress) {
                $RemoveNetIPAddressSplat = @{
                    IPAddress = $CurrentIP.IPAddress
                    InterfaceIndex = $CurrentIP.InterfaceIndex
                    AddressFamily = $CurrentIP.AddressFamily
                    Confirm = $false
                    ErrorAction = 'Stop'
                }

                Remove-NetIPAddress @RemoveNetIPAddressSplat
                    
            }
        }
    }

    foreach ($SingleIP in $IPAddress) {
        # Build parameter hash table
        $Parameters = @{
            IPAddress = $SingleIP
            PrefixLength = $PrefixLength
            InterfaceAlias = $InterfaceAlias
        }

        # Apply the specified IP configuration
        $null = New-NetIPAddress @Parameters -ErrorAction Stop

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

    .PARAMETER PrefixLength
    The prefix length of the IP Address.

    .PARAMETER AddressFamily
    IP address family.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [ValidateNotNullOrEmpty()]
        [String[]]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $InterfaceAlias,

        [uInt32]
        $PrefixLength = 16,

        [ValidateSet('IPv4', 'IPv6')]
        [String]
        $AddressFamily = 'IPv4'
    )

    # Flag to signal whether settings are correct
    [Boolean] $desiredConfigurationMatch = $true

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
        $($LocalizedData.CheckingIPAddressMessage)
        ) -join '')

    Assert-ResourceProperty @PSBoundParameters

    # Get the current IP Address based on the parameters given.
     # First make sure that adapter is available
    [Boolean] $adapterBindingReady = $false
    [DateTime] $startTime = Get-Date

    while (-not $adapterBindingReady -and (((Get-Date) - $startTime).TotalSeconds) -lt 30)
    {
        $GetNetIPAddressSplat = @{
            InterfaceAlias = $InterfaceAlias
            AddressFamily = $AddressFamily
            ErrorAction = 'SilentlyContinue'
        }

        $currentIPs = @(Get-NetIPAddress @GetNetIPAddressSplat)

        if ($currentIPs)
        {
            $adapterBindingReady = $true
        }
        else
        {
            Start-Sleep -Milliseconds 200
        }
    } # while

    # Test if the IP Address passed is present
    foreach ($SingleIP in $IPAddress) {
        if ($SingleIP -notin $currentIPs.IPAddress)
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.IPAddressDoesNotMatchMessage) -f $SingleIP,$currentIPs.IPAddress
                ) -join '' )
            $desiredConfigurationMatch = $false
        }
        else
        {
            Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                $($LocalizedData.IPAddressMatchMessage)
                ) -join '')

            # Filter the IP addresses for the IP address to check
            $filterIP = $currentIPs.Where( { $_.IPAddress -eq $SingleIP } )

            # Only test the Prefix Length if the IP address is present
            if (-not $filterIP.PrefixLength.Equals([byte]$PrefixLength))
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.PrefixLengthDoesNotMatchMessage) -f $PrefixLength,$currentIPs.PrefixLength
                    ) -join '' )
                $desiredConfigurationMatch = $false
            }
            else
            {
                Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                    $($LocalizedData.PrefixLengthMatchMessage)
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

    .PARAMETER PrefixLength
    The prefix length of the IP Address.

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
        [String[]]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $InterfaceAlias,

        [uInt32]
        $PrefixLength = 16,

        [ValidateSet('IPv4', 'IPv6')]
        [String]
        $AddressFamily = 'IPv4'
    )

    if (-not (Get-NetAdapter | Where-Object -Property Name -EQ $InterfaceAlias ))
    {
        $errorId = 'InterfaceNotAvailable'
        $errorCategory = [System.Management.Automation.ErrorCategory]::DeviceError
        $errorMessage = $($LocalizedData.InterfaceNotAvailableError) -f $InterfaceAlias
        $exception = New-Object -TypeName System.InvalidOperationException `
            -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }
    foreach ($SingleIP in $IPAddress) {
        if (-not ([System.Net.Ipaddress]::TryParse($SingleIP, [ref]0)))
        {
            $errorId = 'AddressFormatError'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
            $errorMessage = $($LocalizedData.AddressFormatError) -f $SingleIP
            $exception = New-Object -TypeName System.InvalidOperationException `
                -ArgumentList $errorMessage
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                -ArgumentList $exception, $errorId, $errorCategory, $null

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        $detectedAddressFamily = ([System.Net.IPAddress]$SingleIP).AddressFamily.ToString()
        if (($detectedAddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork.ToString()) `
            -and ($AddressFamily -ne 'IPv4'))
        {
            $errorId = 'AddressMismatchError'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
            $errorMessage = $($LocalizedData.AddressIPv4MismatchError) -f $SingleIP,$AddressFamily
            $exception = New-Object -TypeName System.InvalidOperationException `
                -ArgumentList $errorMessage
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                -ArgumentList $exception, $errorId, $errorCategory, $null

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        if (($detectedAddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6.ToString()) `
            -and ($AddressFamily -ne 'IPv6'))
        {
            $errorId = 'AddressMismatchError'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
            $errorMessage = $($LocalizedData.AddressIPv6MismatchError) -f $SingleIP,$AddressFamily
            $exception = New-Object -TypeName System.InvalidOperationException `
                -ArgumentList $errorMessage
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                -ArgumentList $exception, $errorId, $errorCategory, $null

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }

    if ((
            ($AddressFamily -eq 'IPv4') `
                -and (($PrefixLength -lt [uint32]0) -or ($PrefixLength -gt [uint32]32))
            ) -or (
            ($AddressFamily -eq 'IPv6') `
                -and (($PrefixLength -lt [uint32]0) -or ($PrefixLength -gt [uint32]128))
        ))
    {
        $errorId = 'PrefixLengthError'
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
        $errorMessage = $($LocalizedData.PrefixLengthError) -f $PrefixLength,$AddressFamily
        $exception = New-Object -TypeName System.InvalidOperationException `
            -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }
} # Assert-ResourceProperty

Export-ModuleMember -function *-TargetResource
