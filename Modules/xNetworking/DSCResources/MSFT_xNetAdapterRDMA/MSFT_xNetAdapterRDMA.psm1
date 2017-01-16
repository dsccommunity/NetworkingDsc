# Get the path to the shared modules folder
$script:ModulesFolderPath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent)) `
                                      -ChildPath 'Modules'

# Import the Networking Resource Helper Module
Import-Module -Name (Join-Path -Path $script:ModulesFolderPath `
                               -ChildPath (Join-Path -Path 'NetworkingDsc.ResourceHelper' `
                                                     -ChildPath 'NetworkingDsc.ResourceHelper.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData `
    -ResourceName 'MSFT_xNetAdapterRDMA' `
    -ResourcePath $PSScriptRoot

# Import the common networking functions
Import-Module -Name (Join-Path -Path $script:ModulesFolderPath `
                               -ChildPath (Join-Path -Path 'NetworkingDsc.Common' `
                                                     -ChildPath 'NetworkingDsc.Common.psm1'))

<#
.SYNOPSIS
    Gets MSFT_xVMNetAdapterRDMA resource current state.

.PARAMETER Name
    Specifies the name of the network adapter for which the RDMA configuration needs to be retrieved.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [String]
        $Name
    )

    $configuration = @{
        Name = $Name
    }

    try
    {
        Write-Verbose -Message $localizedData.CheckNetAdapter
        $netAdapter = Get-NetAdapterRdma -Name $Name -ErrorAction Stop
        if ($netAdapter)
        {
            Write-Verbose -Message $localizedData.CheckNetAdapterRDMA
            $configuration.Add('Enabled',$netAdapter.Enabled)
            return $configuration
        }
    }
    catch
    {
        throw $localizedData.NetAdapterNotFound
    }
}

<#
.SYNOPSIS
    Sets MSFT_xVMNetAdapterRDMA resource state.

.PARAMETER Name
    Specifies the name of the network adapter for which the
    RDMA configuration needs to be retrieved.

.PARAMETER Enabled
    Specifies if the RDMA configuration should be enabled or disabled.
    This is a boolean value and the default is $true.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [String]
        $Name,

        [parameter()]
        [Boolean]
        $Enabled = $true
    )

    $configuration = @{
        Name = $Name
    }

    try
    {
        Write-Verbose -Message $localizedData.CheckNetAdapter
        $netAdapter = Get-NetAdapterRdma -Name $Name -ErrorAction Stop
        if ($netAdapter)
        {
            Write-Verbose -Message $localizedData.CheckNetAdapterRDMA
            if ($netAdapter.Enabled -ne $Enabled)
            {
                Write-Verbose -Message $localizedData.NetAdapterRDMADifferent
                Write-Verbose -Message $localizedData.SetNetAdapterRDMA
                Set-NetAdapterRdma -Name $Name -Enabled $Enabled
            }
        }
    }
    catch
    {
        throw $localizedData.NetAdapterNotFound
    }
}

<#
.SYNOPSIS
    Tests if MSFT_xVMNetAdapterRDMA resource state is indeed desired state or not.

.PARAMETER Name
    Specifies the name of the network adapter for which the
    RDMA configuration needs to be retrieved.

.PARAMETER Enabled
    Specifies if the RDMA configuration should be enabled or disabled.
    This is a boolean value and the default is $true.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [String]
        $Name,

        [parameter()]
        [Boolean]
        $Enabled = $true
    )

    try
    {
        Write-Verbose -Message $localizedData.CheckNetAdapter
        $netAdapter = Get-NetAdapterRdma -Name $Name -ErrorAction Stop
        if ($netAdapter)
        {
            Write-Verbose -Message $localizedData.CheckNetAdapterRDMA
            if ($netAdapter.Enabled -ne $Enabled)
            {
                Write-Verbose -Message $localizedData.NetAdapterRDMADifferent
                return $false
            }
            else
            {
                Write-Verbose -Message $localizedData.NetAdapterRDMAMatches
                return $true
            }
        }
    }
    catch
    {
        throw $localizedData.NetAdapterNotFound
    }
}
