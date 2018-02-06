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
    -ResourceName 'MSFT_xWINSSetting' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
    Returns the current WINS settings.

    .PARAMETER IsSingleInstance
    Specifies the resource is a single instance, the value must be 'Yes'.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.GettingWinsSettingMessage)
        ) -join '' )

    # 0 equals off, 1 equals on
    $enableLmHostsRegistryKey = Get-ItemProperty `
        -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' `
        -Name EnableLMHOSTS `
        -ErrorAction SilentlyContinue

    $enableLmHosts = ($enableLmHostsRegistryKey.EnableLMHOSTS -eq 1)

    # 0 equals off, 1 equals on
    $enableDnsRegistryKey = Get-ItemProperty `
        -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' `
        -Name EnableDNS `
        -ErrorAction SilentlyContinue

    if ($enableDnsRegistryKey)
    {
        $enableDns = ($enableDnsRegistryKey.EnableDNS -eq 1)
    }
    else
    {
        # if the key does not exist, then set the default which is enabled.
        $enableDns = $true
    }

    return @{
        IsSingleInstance = 'Yes'
        EnableLmHosts    = $enableLmHosts
        EnableDns        = $enableDns
    }
} # Get-TargetResource

<#
    .SYNOPSIS
    Sets the current configuration for the LMHOSTS Lookup setting.

    .PARAMETER IsSingleInstance
    Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER EnableLmHosts
    Specifies if LMHOSTS lookup should be enabled for all network
    adapters with TCP/IP enabled.

    .PARAMETER EnableDns
    Specifies if DNS is enabled for name resolution over WINS for
    all network adapters with TCP/IP enabled.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [System.Boolean]
        $EnableLmHosts,

        [Parameter()]
        [System.Boolean]
        $EnableDns
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.SettingWinsSettingMessage)
        ) -join '' )

    # Get the current values of the WINS settings
    $currentState = Get-TargetResource -IsSingleInstance 'Yes'

    if (-not $PSBoundParameters.ContainsKey('EnableLmHosts'))
    {
        $EnableLmHosts = $currentState.EnableLmHosts
    }

    if (-not $PSBoundParameters.ContainsKey('EnableDns'))
    {
        $EnableDns = $currentState.EnableDNS
    }

    $result = Invoke-CimMethod `
        -ClassName Win32_NetworkAdapterConfiguration `
        -MethodName EnableWins `
        -Arguments @{
            DNSEnabledForWINSResolution = $EnableDns
            WINSEnableLMHostsLookup     = $EnableLmHosts
        }

    if ($result.ReturnValue -ne 0)
    {
        New-InvalidOperationException `
            -Message ($localizedData.FailedUpdatingWinsSettingError -f $result.ReturnValue)
    }

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.WinsSettingUpdatedMessage)
        ) -join '' )
} # Set-TargetResource

<#
    .SYNOPSIS
    Tests the current configuration for the LMHOSTS Lookup setting.

    .PARAMETER IsSingleInstance
    Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER EnableLmHosts
    Specifies if LMHOSTS lookup should be enabled for all network
    adapters with TCP/IP enabled.

    .PARAMETER EnableDns
    Specifies if DNS is enabled for name resolution over WINS for
    all network adapters with TCP/IP enabled.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [System.Boolean]
        $EnableLmHosts,

        [Parameter()]
        [System.Boolean]
        $EnableDns
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.TestingWinsSettingMessage)
        ) -join '' )

    # Get the current values of the WINS settings
    $currentState = Get-TargetResource -IsSingleInstance 'Yes'

    return Test-DscParameterState -CurrentValues $currentState -DesiredValues $PSBoundParameters
} # Test-TargetResource

Export-ModuleMember -Function *-TargetResource
