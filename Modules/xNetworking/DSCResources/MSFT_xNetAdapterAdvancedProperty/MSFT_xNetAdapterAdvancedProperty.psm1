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
    -ResourceName 'MSFT_xNetAdapterAdvancedProperty' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
.SYNOPSIS
    Gets the current state of NetAdapterRss for a adapter.

.PARAMETER Name
    Specifies the Name of the network adapter to check.

.PARAMETER State
    Specifies the Rss state for the protocol.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $NetworkAdapterName,

        [Parameter(Mandatory = $true)]
        [String]
        $RegistryKeyword,

        [Parameter(Mandatory = $true)]
        [String]
        $RegistryValue
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $localizedData.CheckingNetAdapterMessage
        ) -join '')

    try
    {
        $netAdapteradvprop = Get-NetAdapterAdvancedProperty -Name $networkAdapterName  -RegistryKeyword $RegistryKeyword -ErrorAction Stop
    }
    catch
    {
        New-InvalidOperationException `
            -Message ($LocalizedData.NetAdapterNotFoundMessage)
    }

    if ($netAdapteradvprop)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.NetAdapterTestingStateMessage -f $NetworkAdapterName, $RegistryKeyword)
            ) -join '')

        $result = @{
            Name    = $NetworkAdapterName
            RegistryKeyword = $RegistryKeyword
            DisplayValue = $netadapteradvprop.DisplayValue
            RegistryValue = $netadapteradvprop.RegistryValue
        }

        return $result
    }
}

<#
.SYNOPSIS
    Sets the NetAdapterRss resource state.

.PARAMETER Name
    Specifies the Name of the network adapter to check.

.PARAMETER State
    Specifies the Rss state for the protocol.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $NetworkAdapterName,

        [Parameter(Mandatory = $true)]
        [String]
        $RegistryKeyword,

        [Parameter(Mandatory = $true)]
        [String]
        $RegistryValue
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $localizedData.CheckingNetAdapterMessage
        ) -join '')

    try
    {
        $netAdapteradvprop = Get-NetAdapterAdvancedProperty -Name $networkAdapterName  -RegistryKeyword $RegistryKeyword -ErrorAction Stop
    }
    catch
    {
        New-InvalidOperationException `
            -Message ($LocalizedData.NetAdapterNotFoundMessage)
    }

    if ($netAdapteradvprop)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.NetAdapterTestingStateMessage -f $NetworkAdapterName, $RegistryKeyword)
            ) -join '')

        if ($RegistryValue -ne $netadapteradvprop.RegistryValue)
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.NetAdapterApplyingChangesMessage -f `
                            $NetworkAdapterName,$netadapteradvprop.RegistryValue,$RegistryValue )
                ) -join '')

            Get-NetAdapterAdvancedProperty -Name $networkAdapterName  -RegistryKeyword $RegistryKeyword | Set-NetAdapterAdvancedProperty -RegistryValue $RegistryValue
        }
    }
}

<#
.SYNOPSIS
    Tests if the NetAdapterRss resource state is desired state.

.PARAMETER Name
    Specifies the Name of the network adapter to check.

.PARAMETER State
    Specifies the Rss state for the protocol.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $NetworkAdapterName,

        [Parameter(Mandatory = $true)]
        [String]
        $RegistryKeyword,

        [Parameter(Mandatory = $true)]
        [String]
        $RegistryValue
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $localizedData.CheckingNetAdapterMessage
        ) -join '')

    try
    {
        $netAdapteradvprop = Get-NetAdapterAdvancedProperty -Name $networkAdapterName  -RegistryKeyword $RegistryKeyword -ErrorAction Stop
    }
    catch
    {
        New-InvalidOperationException `
            -Message ($LocalizedData.NetAdapterNotFoundMessage)
    }

    if ($netAdapteradvprop)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $localizedData.NetAdapterTestingStateMessage -f `
                    $NetworkAdapterName, $RegistryKeyword
            ) -join '')

        If ($RegistryValue -eq $netadapteradvprop.RegistryValue) {
            return $true
        }
        else {
            return $false
        }
    }
}
