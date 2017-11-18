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
    ResourceName = 'MSFT_xIPAddressOption'
    ResourcePath = (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)
}
$localizedData = Get-LocalizedData @localizedDataSplat

<#
    .SYNOPSIS
    Returns the current state of an IP address option.

    .PARAMETER IPAddress
    The desired IP address.

    .PARAMETER SkipAsSource
    The skip as source option.
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
        $IPAddress,

        [Parameter()]
        [ValidateSet('True', 'False')]
        [System.String]
        $SkipAsSource = 'False'
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.GettingIPAddressOptionMessage)
        ) -join '')

    $currentIPAddress = Get-NetIPAddress -IPAddress $IPAddress

    $returnValue = @{
        IPAddress    = $IPAddress
        SkipAsSource = [String] $currentIPAddress.SkipAsSource
    }

    return $returnValue
}

<#
    .SYNOPSIS
    Set the IP address options.

    .PARAMETER IPAddress
    The desired IP address.

    .PARAMETER SkipAsSource
    The skip as source option.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $IPAddress,

        [Parameter()]
        [ValidateSet('True', 'False')]
        [System.String]
        $SkipAsSource = 'False'
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.ApplyingIPAddressOptionMessage)
        ) -join '')

    $currentConfig = Get-TargetResource @PSBoundParameters

    if ($currentConfig.SkipAsSource -ne $SkipAsSource)
    {
        $boolSkipAsSource = $SkipAsSource -eq 'True'
        Set-NetIPAddress -IPAddress $IPAddress -SkipAsSource $boolSkipAsSource
    }
}

<#
    .SYNOPSIS
    Tests the IP address options.

    .PARAMETER IPAddress
    The desired IP address.

    .PARAMETER SkipAsSource
    The skip as source option.
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
        $IPAddress,

        [Parameter()]
        [ValidateSet('True', 'False')]
        [System.String]
        $SkipAsSource = 'False'
    )

    # Flag to signal whether settings are correct
    [System.Boolean] $desiredConfigurationMatch = $true

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($LocalizedData.CheckingIPAddressOptionMessage)
        ) -join '')

    $currentConfig = Get-TargetResource @PSBoundParameters

    $desiredConfigurationMatch = $desiredConfigurationMatch -and
                                 $currentConfig.SkipAsSource -eq $SkipAsSource

    return $desiredConfigurationMatch
}

Export-ModuleMember -function *-TargetResource
