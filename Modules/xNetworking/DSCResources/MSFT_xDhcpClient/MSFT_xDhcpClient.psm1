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
$LocalizedData = Get-LocalizedData `
    -ResourceName 'MSFT_xDhcpClient' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
    Returns the current state of the DHCP Client for an interface.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the DHCP Client is set.

    .PARAMETER AddressFamily
    IP address family.

    .PARAMETER State
    The desired state of the DHCP Client.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [System.String]
        $AddressFamily,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $State
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.GettingDHCPClientMessage) `
                -f $InterfaceAlias, $AddressFamily `
        ) -join '')

    Assert-ResourceProperty @PSBoundParameters

    $currentDHCPClient = Get-NetIPInterface `
        -InterfaceAlias $InterfaceAlias `
        -AddressFamily $AddressFamily

    $returnValue = @{
        State          = $currentDHCPClient.Dhcp
        AddressFamily  = $AddressFamily
        InterfaceAlias = $InterfaceAlias
    }

    return $returnValue
}

<#
    .SYNOPSIS
    Sets the DHCP Client for an interface.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the DHCP Client is set.

    .PARAMETER AddressFamily
    IP address family.

    .PARAMETER State
    The desired state of the DHCP Client.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [System.String]
        $AddressFamily,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $State
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.ApplyingDHCPClientMessage) `
                -f $InterfaceAlias, $AddressFamily `
        ) -join '')

    Assert-ResourceProperty @PSBoundParameters

    $null = Get-NetIPInterface `
        -InterfaceAlias $InterfaceAlias `
        -AddressFamily $AddressFamily

    # The DHCP Client is in a different state - so change it.
    Set-NetIPInterface `
        -InterfaceAlias $InterfaceAlias `
        -AddressFamily $AddressFamily `
        -Dhcp $State `
        -ErrorAction Stop

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($LocalizedData.DHCPClientSetStateMessage) `
                -f $InterfaceAlias, $AddressFamily, $State `
        ) -join '' )

} # Set-TargetResource

<#
    .SYNOPSIS
    Tests the state of the DHCP Client for an interface.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the DHCP Client is set.

    .PARAMETER AddressFamily
    IP address family.

    .PARAMETER State
    The desired state of the DHCP Client.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [System.String]
        $AddressFamily,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $State
    )

    # Flag to signal whether settings are correct
    [System.Boolean] $desiredConfigurationMatch = $true

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($LocalizedData.CheckingDHCPClientMessage) `
                -f $InterfaceAlias, $AddressFamily `
        ) -join '')

    Assert-ResourceProperty @PSBoundParameters

    $currentDHCPClient = Get-NetIPInterface `
        -InterfaceAlias $InterfaceAlias `
        -AddressFamily $AddressFamily

    # The DHCP Client is in a different state - so change it.
    if ($currentDHCPClient.DHCP -ne $State)
    {
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                $($LocalizedData.DHCPClientDoesNotMatchMessage) `
                    -f $InterfaceAlias, $AddressFamily, $State `
            ) -join '' )
        $desiredConfigurationMatch = $false
    }

    return $desiredConfigurationMatch
} # Test-TargetResource

<#
    .SYNOPSIS
    Function will check the interface exists.
    If any problems are detected an exception will be thrown.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the DHCP Client is set.

    .PARAMETER AddressFamily
    IP address family.

    .PARAMETER State
    The desired state of the DHCP Client.
#>
function Assert-ResourceProperty
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [System.String]
        $AddressFamily,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $State
    )

    if (-not (Get-NetAdapter | Where-Object -Property Name -EQ $InterfaceAlias ))
    {
        New-InvalidOperationException `
            -Message ($LocalizedData.InterfaceNotAvailableError -f $InterfaceAlias)
    }
} # Assert-ResourceProperty

Export-ModuleMember -function *-TargetResource
