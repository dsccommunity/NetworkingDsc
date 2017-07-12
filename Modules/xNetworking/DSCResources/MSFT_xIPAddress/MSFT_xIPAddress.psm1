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
        [String[]]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $InterfaceAlias,

        [Parameter(Mandatory = $True)]
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
    $currentIPAddress = Get-NetIPAddress @GetNetIPAddressSplat

    $currentIPAddressWithPrefix = $currentIPAddress |
        Foreach-Object { "$($_.IPAddress)/$($_.prefixLength)" }

    $returnValue = @{
        IPAddress      = @($currentIPAddressWithPrefix)
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
        [String[]]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $InterfaceAlias,

        [Parameter(Mandatory = $True)]
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
        $prefixLength = 64
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
        foreach ($defaultRoute in $defaultRoutes)
        {
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
        foreach ($CurrentIP in $CurrentIPs)
        {
            $RemoveIP = $False
            if ($CurrentIP.IPAddress -notin ($IPAddress -replace '\/\S*',''))
            {
                $RemoveIP = $True
            }
            elseif ($CurrentIP.IPAddress -in ($IPAddress -replace '\/\S*',''))
            {
                $ExistingIP = $IPAddress | Where-Object {$_ -match $CurrentIP.IPAddress}
                if ($ExistingIP -ne "$($CurrentIP.IPAddress)/$($CurrentIP.prefixLength)")
                {
                    $RemoveIP = $True
                }
            }

            if ($RemoveIP)
            {
                $RemoveNetIPAddressSplat = @{
                    IPAddress = $CurrentIP.IPAddress
                    InterfaceIndex = $CurrentIP.InterfaceIndex
                    AddressFamily = $CurrentIP.AddressFamily
                    prefixLength = $CurrentIP.prefixLength
                    Confirm = $false
                    ErrorAction = 'Stop'
                }

                Remove-NetIPAddress @RemoveNetIPAddressSplat
            }
        }
    }

    $ipAddressObject = Get-IPAddressPrefix -IPAddress $IPAddress -AddressFamily $AddressFamily

    foreach ($singleIP in $ipAddressObject)
    {
        $prefixLength = $singleIP.prefixLength

        # Build parameter hash table
        $Parameters = @{
            IPAddress = $singleIP.IPAddress
            prefixLength = $prefixLength
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
        [String[]]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $InterfaceAlias,

        [Parameter(Mandatory = $True)]
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

    $ipAddressObject = Get-IPAddressPrefix -IPAddress $IPAddress -AddressFamily $AddressFamily
    # Test if the IP Address passed is present
    foreach ($singleIP in $ipAddressObject)
    {
        $prefixLength = $singleIP.prefixLength
        if ($singleIP.IPAddress -notin $currentIPs.IPAddress)
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.IPAddressDoesNotMatchMessage) -f $singleIP,$currentIPs.IPAddress
                ) -join '' )
            $desiredConfigurationMatch = $false
        }
        else
        {
            Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                $($LocalizedData.IPAddressMatchMessage)
                ) -join '')

            # Filter the IP addresses for the IP address to check
            $filterIP = $currentIPs.Where( { $_.IPAddress -eq $singleIP.IPAddress } )

            # Only test the Prefix Length if the IP address is present
            if (-not $filterIP.prefixLength.Equals([byte]$prefixLength))
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.prefixLengthDoesNotMatchMessage) -f $prefixLength,$currentIPs.prefixLength
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
        [String[]]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $InterfaceAlias,

        [Parameter()]
        [ValidateSet('IPv4', 'IPv6')]
        [String]
        $AddressFamily = 'IPv4'
    )

    $prefixLengthArray = ($IPAddress -split '/')[1]
    If ($prefixLengthArray.Count -ne $IPAddress.Count)
    {
        $prefixLengthArray = $IPAddress | Foreach-Object {
            if ($_ -match '\/\d{1,3}')
            {
                ($_ -split '/')[1]
            }
            else
            {
                if ($_.split('.')[0] -in (0..127))
                {
                    $Value = 8
                }
                elseif ($_.split('.')[0] -in (128..191))
                {
                    $Value = 16
                }
                elseif ($_.split('.')[0] -in (192..223))
                {
                    $Value = 24
                }
                if ($AddressFamily -eq 'IPv6')
                {
                    $value = 64
                }
                $value
            }
        }
    }

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
    foreach ($singleIPAddress in $IPAddress)
    {
        $singleIP = ($singleIPAddress -split '/')[0]

        if (-not ([System.Net.Ipaddress]::TryParse($singleIP, [ref]0)))
        {
            $errorId = 'AddressFormatError'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
            $errorMessage = $($LocalizedData.AddressFormatError) -f $singleIPAddress
            $exception = New-Object -TypeName System.InvalidOperationException `
                -ArgumentList $errorMessage
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                -ArgumentList $exception, $errorId, $errorCategory, $null

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        $detectedAddressFamily = ([System.Net.IPAddress]$singleIP).AddressFamily.ToString()
        if (($detectedAddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork.ToString()) `
            -and ($AddressFamily -ne 'IPv4'))
        {
            $errorId = 'AddressMismatchError'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
            $errorMessage = $($LocalizedData.AddressIPv4MismatchError) -f $singleIPAddress,$AddressFamily
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
            $errorMessage = $($LocalizedData.AddressIPv6MismatchError) -f $singleIPAddress,$AddressFamily
            $exception = New-Object -TypeName System.InvalidOperationException `
                -ArgumentList $errorMessage
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                -ArgumentList $exception, $errorId, $errorCategory, $null

            $PSCmdlet.ThrowTerminatingError($errorRecord)
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
            $errorId = 'prefixLengthError'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
            $errorMessage = $($LocalizedData.prefixLengthError) -f $prefixLength,$AddressFamily
            $exception = New-Object -TypeName System.InvalidOperationException `
                -ArgumentList $errorMessage
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                -ArgumentList $exception, $errorId, $errorCategory, $null

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }
} # Assert-ResourceProperty

Export-ModuleMember -function *-TargetResource
