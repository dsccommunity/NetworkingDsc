$script:ResourceRootPath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent)

# Import the xNetworking Resource Module (to import the common modules)
Import-Module -Name (Join-Path -Path $script:ResourceRootPath -ChildPath 'xNetworking.psd1')

# Import Localization Strings
$localizedData = Get-LocalizedData `
    -ResourceName 'MSFT_xNetAdapterLso' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
.SYNOPSIS
    Gets the current state of NetAdapterLso for a adapter.

.PARAMETER Name
    Specifies the name of the network adapter to check.

.PARAMETER Protocol
    Specifies which protocol to target.

.PARAMETER State
    Specifies the LSO state for the protocol.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [String]
        $Name,

        [parameter(Mandatory = $true)]
        [ValidateSet("V1IPv4","IPv4","IPv6")]
        [String]
        $Protocol,

        [parameter(Mandatory = $true)]
        [Boolean]
        $State
    )

    try 
    {
        Write-Verbose -Message $localizedData.CheckNetAdapter
        $netAdapter = Get-NetAdapterLso -Name $Name -ErrorAction Stop
        if ($netAdapter)
        {
            Write-Verbose -Message $($LocalizedData.CheckingLsoProtocolState -f $Name, $Protocol)
            $result = @{ }
            switch ($Protocol) {
                "V1IPv4" { $result.add('V1IPv4Enabled', $netAdapter.V1IPv4Enabled) }
                "IPv4"   { $result.add('IPv4Enabled', $netAdapter.IPv4Enabled) }
                "IPv6"   { $result.add('IPv6Enabled', $netAdapter.IPv6Enabled) }
                Default {"Should not be called."}
            }
            return $result
        }
    }
    catch 
    {
        throw $localizedData.NetAdapterNotFound
    }

}

<#
.SYNOPSIS
    Sets the NetAdapterLso resource state.

.PARAMETER Name
    Specifies the name of the network adapter to check.

.PARAMETER Protocol
    Specifies which protocol to target.

.PARAMETER State
    Specifies the LSO state for the protocol.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [String]
        $Name,

        [parameter(Mandatory = $true)]
        [ValidateSet("V1IPv4","IPv4","IPv6")]
        [String]
        $Protocol,

        [parameter(Mandatory = $true)]
        [Boolean]
        $State
    )

}

<#
.SYNOPSIS
    Tests if the NetAdapterLso resource state is desired state.

.PARAMETER Name
    Specifies the name of the network adapter to check.

.PARAMETER Protocol
    Specifies which protocol to target.

.PARAMETER State
    Specifies the LSO state for the protocol.
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

        [parameter(Mandatory = $true)]
        [ValidateSet("V1IPv4","IPv4","IPv6")]
        [String]
        $Protocol,

        [parameter(Mandatory = $true)]
        [Boolean]
        $State
    )

}
