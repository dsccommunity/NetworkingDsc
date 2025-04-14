$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Networking Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'NetworkingDsc.Common' `
            -ChildPath 'NetworkingDsc.Common.psm1'))

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

# This must be a script parameter so that it is accessible
$script:dnsPolicyConfigRegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters\DnsPolicyConfig'

<#
    .SYNOPSIS
        Returns the current state of a DNS Client NRPT Rule.

    .PARAMETER Name
        Specifies the name which uniquely identifies a rule.
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
        $Name
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.GettingNrptRuleMessage) `
                -f $Name `
        ) -join '' )

    # Lookup the existing NrptRule
    $NrptRule = Get-NrptRule -Name $Name

    $returnValue = @{
        Name = $Name
    }

    if ($NrptRule)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.NrptRuleExistsMessage) `
                    -f $Name `
            ) -join '' )

        $returnValue += @{
            Ensure                    = 'Present'
            Comment                   = [System.String] $NrptRule.Comment
            DAEnable                  = [System.Boolean] $NrptRule.DAEnable
            DAIPsecEncryptionType     = [System.String] $NrptRule.DAIPsecEncryptionType
            DAIPsecRequired           = [System.Boolean] $NrptRule.DAIPsecRequired
            DANameServers             = [System.String[]] $NrptRule.DANameServers
            DAProxyServerName         = [System.String] $NrptRule.DAProxyServerName
            DAProxyType               = [System.String] $NrptRule.DAProxyType
            DisplayName               = [System.String] $NrptRule.DisplayName
            DnsSecEnable              = [System.Boolean] $NrptRule.DnsSecEnable
            DnsSecIPsecEncryptionType = [System.String] $NrptRule.DnsSecIPsecEncryptionType
            DnsSecIPsecRequired       = [System.Boolean] $NrptRule.DnsSecIPsecRequired
            DnsSecValidationRequired  = [System.Boolean] $NrptRule.DnsSecValidationRequired
            IPsecTrustAuthority       = [System.String] $NrptRule.IPsecTrustAuthority
            NameEncoding              = [System.String] $NrptRule.NameEncoding
            NameServers               = [System.String[]] $NrptRule.NameServers
            Namespace                 = [System.String] $NrptRule.Namespace
        }
    }
    else
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.NrptRuleDoesNotExistMessage) `
                    -f $Name `
            ) -join '' )

        $returnValue += @{
            Ensure = 'Absent'
        }
    }

    return $returnValue
} # Get-TargetResource

<#
    .SYNOPSIS
        Sets a NRPT Rule.

    .PARAMETER Name
        Specifies the name which uniquely identifies a rule.

    .PARAMETER Comment
        Stores administrator notes.

    .PARAMETER DAEnable
        Indicates the rule state for DirectAccess.

    .PARAMETER DAIPsecEncryptionType
        Specifies the Internet Protocol security (IPsec) encryption setting for DirectAccess.

    .PARAMETER DAIPsecRequired
        Indicates that IPsec is required for DirectAccess.

    .PARAMETER DANameServers
        Specifies an array of DNS servers to query when DirectAccess is enabled.

    .PARAMETER DAProxyServerName
        "Specifies the proxy server to use when connecting to the Internet.
        This parameter is only applicable if the DAProxyType parameter is set to UseProxyName.

    .PARAMETER DAProxyType
        Specifies the proxy server type to be used when connecting to the Internet.

    .PARAMETER DisplayName
        Specifies an optional friendly name for the NRPT rule.

    .PARAMETER DnsSecEnable
        Enables Domain Name System Security Extensions (DNSSEC) on the rule.

    .PARAMETER DnsSecIPsecEncryptionType
        Specifies the IPsec tunnel encryption setting.

    .PARAMETER DnsSecIPsecRequired
        Indicates the DNS client must set up an IPsec connection to the DNS server.

    .PARAMETER DnsSecValidationRequired
        Indicates that DNSSEC validation is required.

    .PARAMETER IPsecTrustAuthority
        Specifies the certification authority to validate the IPsec channel.

    .PARAMETER NameEncoding
        Specifies the encoding format for host names in the DNS query.

    .PARAMETER NameServers
        Specifies the DNS servers to which the DNS query is sent when DirectAccess is disabled.

    .PARAMETER Namespace
        Specifies the DNS namespace.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.String]
        $Comment,

        [Parameter()]
        [System.Boolean]
        $DAEnable,

        [Parameter()]
        [ValidateSet('None', 'Low', 'Medium', 'High')]
        [System.String]
        $DAIPsecEncryptionType,

        [Parameter()]
        [System.Boolean]
        $DAIPsecRequired,

        [Parameter()]
        [System.String[]]
        $DANameServers,

        [Parameter()]
        [System.String]
        $DAProxyServerName,

        [Parameter()]
        [ValidateSet('NoProxy', 'UseDefault', 'UseProxyName')]
        [System.String]
        $DAProxyType,

        [Parameter()]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.Boolean]
        $DnsSecEnable,

        [Parameter()]
        [ValidateSet('None', 'Low', 'Medium', 'High')]
        [System.String]
        $DnsSecIPsecEncryptionType,

        [Parameter()]
        [System.Boolean]
        $DnsSecIPsecRequired,

        [Parameter()]
        [System.Boolean]
        $DnsSecValidationRequired,

        [Parameter()]
        [System.String]
        $IPsecTrustAuthority,

        [Parameter()]
        [ValidateSet('Disable', 'Utf8WithMapping', 'Utf8WithoutMapping', 'Punycode')]
        [System.String]
        $NameEncoding,

        [Parameter()]
        [System.String[]]
        $NameServers,

        [Parameter()]
        [System.String]
        $Namespace
    )

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($script:localizedData.SettingNrptRuleMessage) `
            -f $Name `
    ) -join '' )

    # Remove any parameters that can't be splatted.
    $null = $PSBoundParameters.Remove('Ensure')

    # Lookup the existing NrptRule
    $NrptRule = Get-NrptRule -Name $Name

    if ($Ensure -eq 'Present')
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.EnsureNrptRuleExistsMessage) `
                    -f $Name `
            ) -join '' )

        if ($NrptRule)
        {
            # The NrptRule exists - update it
            Set-DnsClientNrptRule @PSBoundParameters `
                -ErrorAction Stop

            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.NrptRuleUpdatedMessage) `
                        -f $Name `
                ) -join '' )
        }
        else
        {
            # The NrptRule does not exit - create it
            Add-NrptRule @PSBoundParameters `
                -ErrorAction Stop

            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.NrptRuleCreatedMessage) `
                        -f $Name `
                ) -join '' )
        }
    }
    else
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.EnsureNrptRuleDoesNotExistMessage) `
                    -f $Name `
            ) -join '' )

        if ($NrptRule)
        {
            <#
                The NrptRule exists - remove it
                Use Force as confirm does not work in DnsClientNrptRule
            #>

            Remove-DnsClientNrptRule -Name $Name `
                -Force `
                -ErrorAction Stop

            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.NrptRuleRemovedMessage) `
                        -f $Name `
                ) -join '' )
        } # if
    } # if
} # Set-TargetResource

<#
    .SYNOPSIS
        Tests the state of a NRPT Rule.

    .PARAMETER Name
        Specifies the name which uniquely identifies a rule.

    .PARAMETER Comment
        Stores administrator notes.

    .PARAMETER DAEnable
        Indicates the rule state for DirectAccess.

    .PARAMETER DAIPsecEncryptionType
        Specifies the Internet Protocol security (IPsec) encryption setting for DirectAccess.

    .PARAMETER DAIPsecRequired
        Indicates that IPsec is required for DirectAccess.

    .PARAMETER DANameServers
        Specifies an array of DNS servers to query when DirectAccess is enabled.

    .PARAMETER DAProxyServerName
        "Specifies the proxy server to use when connecting to the Internet.
        This parameter is only applicable if the DAProxyType parameter is set to UseProxyName.

    .PARAMETER DAProxyType
        Specifies the proxy server type to be used when connecting to the Internet.

    .PARAMETER DisplayName
        Specifies an optional friendly name for the NRPT rule.

    .PARAMETER DnsSecEnable
        Enables Domain Name System Security Extensions (DNSSEC) on the rule.

    .PARAMETER DnsSecIPsecEncryptionType
        Specifies the IPsec tunnel encryption setting.

    .PARAMETER DnsSecIPsecRequired
        Indicates the DNS client must set up an IPsec connection to the DNS server.

    .PARAMETER DnsSecValidationRequired
        Indicates that DNSSEC validation is required.

    .PARAMETER IPsecTrustAuthority
        Specifies the certification authority to validate the IPsec channel.

    .PARAMETER NameEncoding
        Specifies the encoding format for host names in the DNS query.

    .PARAMETER NameServers
        Specifies the DNS servers to which the DNS query is sent when DirectAccess is disabled.

    .PARAMETER Namespace
        Specifies the DNS namespace.
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
        $Name,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.String]
        $Comment,

        [Parameter()]
        [System.Boolean]
        $DAEnable,

        [Parameter()]
        [ValidateSet('None', 'Low', 'Medium', 'High')]
        [System.String]
        $DAIPsecEncryptionType,

        [Parameter()]
        [System.Boolean]
        $DAIPsecRequired,

        [Parameter()]
        [System.String[]]
        $DANameServers,

        [Parameter()]
        [System.String]
        $DAProxyServerName,

        [Parameter()]
        [ValidateSet('NoProxy', 'UseDefault', 'UseProxyName')]
        [System.String]
        $DAProxyType,
    
        [Parameter()]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.Boolean]
        $DnsSecEnable,

        [Parameter()]
        [ValidateSet('None', 'Low', 'Medium', 'High')]
        [System.String]
        $DnsSecIPsecEncryptionType,

        [Parameter()]
        [System.Boolean]
        $DnsSecIPsecRequired,

        [Parameter()]
        [System.Boolean]
        $DnsSecValidationRequired,

        [Parameter()]
        [System.String]
        $IPsecTrustAuthority,

        [Parameter()]
        [ValidateSet('Disable', 'Utf8WithMapping', 'Utf8WithoutMapping', 'Punycode')]
        [System.String]
        $NameEncoding,

        [Parameter()]
        [System.String[]]
        $NameServers,

        [Parameter()]
        [System.String]
        $Namespace
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.TestingNrptRuleMessage) `
                -f $Name `
        ) -join '' )

    # Flag to signal whether settings are correct
    [System.Boolean] $desiredConfigurationMatch = $true

    # Remove any parameters that can't be splatted.
    $null = $PSBoundParameters.Remove('Ensure')

    # Check the parameters
    # Assert-ResourceProperty @PSBoundParameters

    # Lookup the existing NrptRule
    $NrptRule = Get-NrptRule -Name $Name

    if ($Ensure -eq 'Present')
    {
        # The NrptRule should exist
        if ($NrptRule)
        {
            # The NrptRule exists and does - but check the parameters
            $currentState = Get-TargetResource -Name $Name

            return Test-DscParameterState -CurrentValues $currentState -DesiredValues $PSBoundParameters
        }
        else
        {
            # The NrptRule doesn't exist but should
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.NrptRuleDoesNotExistButShouldMessage) `
                        -f $Name `
                ) -join '' )

            $desiredConfigurationMatch = $false
        }
    }
    else
    {
        # The NrptRule should not exist
        if ($NrptRule)
        {
            # The NrptRule exists but should not
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.NrptRuleExistsButShouldNotMessage) `
                        -f $Name `
                ) -join '' )

            $desiredConfigurationMatch = $false
        }
        else
        {
            # The NrptRule does not exist and should not
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.NrptRuleDoesNotExistAndShouldNotMessage) `
                        -f $Name `
                ) -join '' )
        }
    } # if

    return $desiredConfigurationMatch
} # Test-TargetResource

<#
    .SYNOPSIS
        This function looks up DNS Client NRPT Rule using the parameters and returns
        it. If the rule is not found $null is returned.

    .PARAMETER Name
        Specifies the name which uniquely identifies a rule.
#>

function Get-NrptRule
{
    param
    (
        [Parameter()]
        [System.String]
        $Name
    )

    try
    {
        $nrptRule = Get-DnsClientNrptRule `
            -Name $Name `
            -ErrorAction SilentlyContinue
    }
    catch [Microsoft.PowerShell.Cmdletization.Cim.CimJobException]
    {
        $nrptRule = $null
    }
    catch
    {
        throw $_
    }

    return $nrptRule
}

<#
    .SYNOPSIS
        This function create a DNS Client NRPT Rule using the parameters.
        This is a dedicated function adding the Rule Name parameter as
        the built-in Add-DnsClientNrptRule cmdlet does not support it.

    .PARAMETER Name
        Specifies the name which uniquely identifies a rule.

    .PARAMETER Comment
        Stores administrator notes.

    .PARAMETER DAEnable
        Indicates the rule state for DirectAccess.

    .PARAMETER DAIPsecEncryptionType
        Specifies the Internet Protocol security (IPsec) encryption setting for DirectAccess.

    .PARAMETER DAIPsecRequired
        Indicates that IPsec is required for DirectAccess.

    .PARAMETER DANameServers
        Specifies an array of DNS servers to query when DirectAccess is enabled.

    .PARAMETER DAProxyServerName
        "Specifies the proxy server to use when connecting to the Internet.
        This parameter is only applicable if the DAProxyType parameter is set to UseProxyName.

    .PARAMETER DAProxyType
        Specifies the proxy server type to be used when connecting to the Internet.

    .PARAMETER DisplayName
        Specifies an optional friendly name for the NRPT rule.

    .PARAMETER DnsSecEnable
        Enables Domain Name System Security Extensions (DNSSEC) on the rule.

    .PARAMETER DnsSecIPsecEncryptionType
        Specifies the IPsec tunnel encryption setting.

    .PARAMETER DnsSecIPsecRequired
        Indicates the DNS client must set up an IPsec connection to the DNS server.

    .PARAMETER DnsSecValidationRequired
        Indicates that DNSSEC validation is required.

    .PARAMETER IPsecTrustAuthority
        Specifies the certification authority to validate the IPsec channel.

    .PARAMETER NameEncoding
        Specifies the encoding format for host names in the DNS query.

    .PARAMETER NameServers
        Specifies the DNS servers to which the DNS query is sent when DirectAccess is disabled.

    .PARAMETER Namespace
        Specifies the DNS namespace.
#>
function Add-NrptRule
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Comment,

        [Parameter()]
        [System.Boolean]
        $DAEnable,

        [Parameter()]
        [ValidateSet('None', 'Low', 'Medium', 'High')]
        [System.String]
        $DAIPsecEncryptionType,

        [Parameter()]
        [System.Boolean]
        $DAIPsecRequired,

        [Parameter()]
        [System.String[]]
        $DANameServers,

        [Parameter()]
        [System.String]
        $DAProxyServerName,

        [Parameter()]
        [ValidateSet('NoProxy', 'UseDefault', 'UseProxyName')]
        [System.String]
        $DAProxyType,

        [Parameter()]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.Boolean]
        $DnsSecEnable,

        [Parameter()]
        [ValidateSet('None', 'Low', 'Medium', 'High')]
        [System.String]
        $DnsSecIPsecEncryptionType,

        [Parameter()]
        [System.Boolean]
        $DnsSecIPsecRequired,

        [Parameter()]
        [System.Boolean]
        $DnsSecValidationRequired,

        [Parameter()]
        [System.String]
        $IPsecTrustAuthority,

        [Parameter()]
        [ValidateSet('Disable', 'Utf8WithMapping', 'Utf8WithoutMapping', 'Punycode')]
        [System.String]
        $NameEncoding,

        [Parameter()]
        [System.String[]]
        $NameServers,

        [Parameter()]
        [System.String]
        $Namespace
    )

    # Remove Name parameter as Add-DnsClientNrptRule cmdlet doesn't support it
    $null = $PSBoundParameters.Remove("Name")

    # The NrptRule does not exit - create it (PassThru to get the name of the rule created)
    $NrptRuleName = (Add-DnsClientNrptRule @PSBoundParameters -PassThru).Name
    # If rule has been created, rename it by registry as Name cannot be provided in Add-DnsClientNrptRule cmdlet
    if (Test-IsGuid -InputValue $NrptRuleName)
    {
        # Rename the registry key
        Rename-Item -Path "$($script:dnsPolicyConfigRegistryPath)\$($NrptRuleName)" `
        -NewName $Name `
        -ErrorAction Stop
    }
}

<#
    .SYNOPSIS
        This function check if the string provided is a GUID.

    .PARAMETER InputValue
        Specifies the value to test.
#>
function Test-IsGuid 
{
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [System.String]
        $InputValue
    )

    try 
    {
        # Attempt to parse the string as a GUID
        [void][Guid]::Parse($InputValue)
        # If successful, return true
        return $true
    }
    catch
    {
        # If an exception is thrown, the string is not a valid GUID
        return $false
    }
}


Export-ModuleMember -Function *-TargetResource
