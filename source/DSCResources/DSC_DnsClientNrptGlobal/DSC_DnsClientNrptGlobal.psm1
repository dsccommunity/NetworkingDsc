$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Networking Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'NetworkingDsc.Common' `
            -ChildPath 'NetworkingDsc.Common.psm1'))

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    This is an array of all the parameters used by this resource.
#>
$resourceData = Import-LocalizedData `
    -BaseDirectory $PSScriptRoot `
    -FileName 'DSC_DnsClientNrptGlobal.data.psd1'

# This must be a script parameter so that it is accessible
$script:parameterList = $resourceData.ParameterList

<#
    .SYNOPSIS
        Returns the current DNS Client Nrpt Global Settings.

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
            $($script:localizedData.GettingDnsClientNrptGlobalMessage)
        ) -join '' )

    # Get the current DNS Client Global Settings
    $DnsClientNrptGlobal = Get-DnsClientNrptGlobal `
        -ErrorAction Stop

    # Generate the return object.
    $returnValue = @{
        IsSingleInstance = 'Yes'
    }

    foreach ($parameter in $script:parameterList)
    {
        $returnValue += @{
            $parameter.Name = $DnsClientNrptGlobal.$($parameter.name)
        }
    } # foreach

    return $returnValue
} # Get-TargetResource

<#
    .SYNOPSIS
        Sets the DNS Client NRPT Global Settings.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER EnableDAForAllNetworks
        Specifies DirectAccess (DA) settings.

    .PARAMETER QueryPolicy.
        Specifies the DNS client query policy.

    .PARAMETER SecureNameQueryFallback
        Specifies the DNS client name resolution fallback policy.
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
        [ValidateSet('EnableOnNetworkID', 'EnableAlways', 'Disable', 'DisableDA')]
        [System.String]
        $EnableDAForAllNetworks,

        [Parameter()]
        [System.String]
        [ValidateSet('Disable', 'QueryIPv6Only', 'QueryBoth')]
        $QueryPolicy,

        [Parameter()]
        [System.String]
        [ValidateSet('Disable', 'FallbackSecure', 'FallbackUnsecure', 'FallbackPrivate')]
        $SecureNameQueryFallback
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.SettingDnsClientNrptGlobalMessage)
        ) -join '' )

    # Get the current DNS Client Nrpt Global Settings
    $DnsClientNrptGlobal = Get-DnsClientNrptGlobal `
        -ErrorAction Stop

    # Generate a list of parameters that will need to be changed.
    $changeParameters = @{}

    foreach ($parameter in $script:parameterList)
    {
        $parameterSourceValue = $DnsClientNrptGlobal.$($parameter.name)
        $parameterNewValue = (Get-Variable -Name ($parameter.name)).Value

        if ($PSBoundParameters.ContainsKey($parameter.Name) `
                -and (Compare-Object -ReferenceObject $parameterSourceValue -DifferenceObject $parameterNewValue -SyncWindow 0))
        {
            $changeParameters += @{
                $($parameter.name) = $parameterNewValue
            }

            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.DnsClientNrptGlobalUpdateParameterMessage) `
                        -f $parameter.Name,($parameterNewValue -join ',')
                ) -join '' )
        } # if
    } # foreach

    if ($changeParameters.Count -gt 0)
    {
        # Update any parameters that were identified as different
        $null = Set-DnsClientNrptGlobal `
            @ChangeParameters `
            -ErrorAction Stop

        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.DnsClientNrptGlobalUpdatedMessage)
            ) -join '' )
    } # if
} # Set-TargetResource

<#
    .SYNOPSIS
        Tests the state of DNS Client Nrpt Global Settings.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER EnableDAForAllNetworks
        Specifies DirectAccess (DA) settings.

    .PARAMETER QueryPolicy.
        Specifies the DNS client query policy.

    .PARAMETER SecureNameQueryFallback
        Specifies the DNS client name resolution fallback policy.
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
        [ValidateSet('EnableOnNetworkID', 'EnableAlways', 'Disable', 'DisableDA')]
        [System.String]
        $EnableDAForAllNetworks,

        [Parameter()]
        [System.String]
        [ValidateSet('Disable', 'QueryIPv6Only', 'QueryBoth')]
        $QueryPolicy,

        [Parameter()]
        [System.String]
        [ValidateSet('Disable', 'FallbackSecure', 'FallbackUnsecure', 'FallbackPrivate')]
        $SecureNameQueryFallback
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.TestingDnsClientNrptGlobalMessage)
        ) -join '' )

    # Flag to signal whether settings are correct
    $desiredConfigurationMatch = $true

    # Get the current DNS Client Nrpt Global Settings
    $DnsClientNrptGlobal = Get-DnsClientNrptGlobal `
        -ErrorAction Stop

    # Check each parameter
    foreach ($parameter in $script:parameterList)
    {
        $parameterSourceValue = $DnsClientNrptGlobal.$($parameter.name)
        $parameterNewValue = (Get-Variable -Name ($parameter.name)).Value

        if ($parameterNewValue -ne $parameterSourceValue)
        {
            Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($script:localizedData.DnsClientNrptGlobalParameterNeedsUpdateMessage) `
                -f $parameter.Name, ($parameterSourceValue -join ','), ($parameterNewValue -join ',')
            ) -join '')
            $desiredConfigurationMatch = $false
        }

    } # foreach

    return $desiredConfigurationMatch
} # Test-TargetResource

Export-ModuleMember -Function *-TargetResource
