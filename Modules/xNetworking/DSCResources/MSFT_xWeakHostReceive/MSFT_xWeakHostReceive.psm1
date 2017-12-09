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
    -ResourceName 'MSFT_xWeakHostReceive' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
    Returns the current state of the Weak Host Send setting for an interface.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the Weak Host setting is set.

    .PARAMETER AddressFamily
    IP address family.

    .PARAMETER State
    The desired state of the Weak Host Receive setting.
#>
function Get-TargetResource
{
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
            $($LocalizedData.GettingWeakHostReceiveMessage) `
                -f $InterfaceAlias, $AddressFamily `
        ) -join '')

    Assert-ResourceProperty @PSBoundParameters

    $currentWeakHostReceive = Get-NetIPInterface `
        -InterfaceAlias $InterfaceAlias `
        -AddressFamily $AddressFamily

    $returnValue = @{
        State          = $currentWeakHostReceive.WeakHostReceive
        AddressFamily  = $AddressFamily
        InterfaceAlias = $InterfaceAlias
    }
    return $returnValue
}

<#
    .SYNOPSIS
    Sets the Weak Host Receive setting for an interface.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the Weak Host Setting is set.

    .PARAMETER AddressFamily
    IP address family.

    .PARAMETER State
    The desired state of the Weak Host Receive setting.
#>
function Set-TargetResource
{
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
            $($LocalizedData.ApplyingWeakHostReceiveMessage) `
                -f $InterfaceAlias, $AddressFamily `
        ) -join '')

    Assert-ResourceProperty @PSBoundParameters

    $null = Get-NetIPInterface `
        -InterfaceAlias $InterfaceAlias `
        -AddressFamily $AddressFamily

    # The Weak Host Receive setting is in a different state - so change it.
    Set-NetIPInterface `
        -InterfaceAlias $InterfaceAlias `
        -AddressFamily $AddressFamily `
        -WeakHostReceive $State `
        -ErrorAction Stop

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($LocalizedData.WeakHostReceiveSetStateMessage) `
                -f $InterfaceAlias, $AddressFamily, $State `
        ) -join '' )
} # Set-TargetResource

<#
    .SYNOPSIS
    Tests the state of the Weak Host Receive setting for an interface.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the Weak Host Receive setting is set.

    .PARAMETER AddressFamily
    IP address family.

    .PARAMETER State
    The desired state of the Weak Host Receive setting.
#>
function Test-TargetResource
{
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
            $($LocalizedData.CheckingWeakHostReceiveMessage) `
                -f $InterfaceAlias, $AddressFamily `
        ) -join '')

    Assert-ResourceProperty @PSBoundParameters

    $currentWeakHostReceive = Get-NetIPInterface `
        -InterfaceAlias $InterfaceAlias `
        -AddressFamily $AddressFamily

    # The Weak Host Receive setting is in a different state - so change it.
    if ($currentWeakHostReceive.WeakHostReceive -ne $State)
    {
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                $($LocalizedData.WeakHostReceiveDoesNotMatchMessage) `
                    -f $InterfaceAlias, $AddressFamily, $State `
            ) -join '' )
        $desiredConfigurationMatch = $false
    }

    return $desiredConfigurationMatch
} # Test-TargetResource

<#
    .SYNOPSIS
    Function will check if the interface exists.
    If any problems are detected an exception will be thrown.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the Weak Host Receive setting is set.

    .PARAMETER AddressFamily
    IP address family.

    .PARAMETER State
    The desired state of the Weak Host Receive setting.
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
