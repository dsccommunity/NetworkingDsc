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
    -ResourceName 'MSFT_xProxySettings' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)


# Registry key paths for proxy settings
$script:policyInternetSettingsRegistryKeyPath = 'SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings'
$script:connectionsRegistryKeyPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections'
$script:internetSettingsRegistryKeyPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings'
$script:controlPanelRegistryKeyPath = 'SOFTWARE\Policies\Microsoft\Internet Explorer\Control Panel'

<#
    .SYNOPSIS
        Returns the current state of the proxy settings for
        the computer.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the
        value must be 'Yes'.
#>
function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance
    )

    return $returnValue
}

<#
    .SYNOPSIS
        Sets the current state of the proxy settings for
        the computer.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the
        value must be 'Yes'.

    .PARAMETER Ensure
        Specifies if computer proxy settings should be set.
        Defaults to 'Present'.

    .PARAMETER ConnectionType
        Defines if the proxy settings should be configured
        for default connections, legacy connections or all
        connections. Defaults to 'All'.

    .PARAMETER EnableAutoDetection
        Enable automatic detection of the proxy settings. Defaults
        to 'False'.

    .PARAMETER EnableAutoConfiguration
        Use automatic configuration script for specifying proxy
        settings. Defaults to 'False'.

    .PARAMETER EnableManualProxy
        Use manual proxy server settings. Defaults to 'False'.

    .PARAMETER AutoConfigURL
        The URL of the automatic configuration script to specify
        the proxy settings. Should be specified if 'EnableAutoConfiguration'
        is 'True'.

    .PARAMETER ProxyServer
        The address and port of the manual proxy server to use.
        Should be specified if 'EnableManualProxy' is 'True'.

    .PARAMETER ProxyServerExceptions
        Bypass proxy server for addresses starting with addresses
        in this list.

    .PARAMETER ProxyServerBypassLocal
        Bypass proxy server for local addresses. Defaults to 'False'.
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
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateSet('All','Default','Legacy')]
        [System.String]
        $ConnectionType = 'All',

        [Parameter()]
        [System.Boolean]
        $EnableAutoDetection = $false,

        [Parameter()]
        [System.Boolean]
        $EnableAutoConfiguration = $false,

        [Parameter()]
        [System.Boolean]
        $EnableManualProxy = $false,

        [Parameter()]
        [System.String]
        $AutoConfigURL,

        [Parameter()]
        [System.String]
        $ProxyServer,

        [Parameter()]
        [System.String[]]
        $ProxyServerExceptions = @(),

        [Parameter()]
        [System.Boolean]
        $ProxyServerBypassLocal = $false
    )

} # Set-TargetResource

<#
    .SYNOPSIS
        Tests the current state of the proxy settings for
        the computer.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the
        value must be 'Yes'.

    .PARAMETER Ensure
        Specifies if computer proxy settings should be set.
        Defaults to 'Present'.

    .PARAMETER ConnectionType
        Defines if the proxy settings should be configured
        for default connections, legacy connections or all
        connections. Defaults to 'All'.

    .PARAMETER EnableAutoDetection
        Enable automatic detection of the proxy settings. Defaults
        to 'False'.

    .PARAMETER EnableAutoConfiguration
        Use automatic configuration script for specifying proxy
        settings. Defaults to 'False'.

    .PARAMETER EnableManualProxy
        Use manual proxy server settings. Defaults to 'False'.

    .PARAMETER AutoConfigURL
        The URL of the automatic configuration script to specify
        the proxy settings. Should be specified if 'EnableAutoConfiguration'
        is 'True'.

    .PARAMETER ProxyServer
        The address and port of the manual proxy server to use.
        Should be specified if 'EnableManualProxy' is 'True'.

    .PARAMETER ProxyServerExceptions
        Bypass proxy server for addresses starting with addresses
        in this list.

    .PARAMETER ProxyServerBypassLocal
        Bypass proxy server for local addresses. Defaults to 'False'.
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
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateSet('All','Default','Legacy')]
        [System.String]
        $ConnectionType = 'All',

        [Parameter()]
        [System.Boolean]
        $EnableAutoDetection = $false,

        [Parameter()]
        [System.Boolean]
        $EnableAutoConfiguration = $false,

        [Parameter()]
        [System.Boolean]
        $EnableManualProxy = $false,

        [Parameter()]
        [System.String]
        $AutoConfigURL,

        [Parameter()]
        [System.String]
        $ProxyServer,

        [Parameter()]
        [System.String[]]
        $ProxyServerExceptions = @(),

        [Parameter()]
        [System.Boolean]
        $ProxyServerBypassLocal = $false
    )

} # Test-TargetResource

<#
    .SYNOPSIS
        Gets the computer proxy settings.
#>
function Get-ComputerProxySettings
{
    [CmdletBinding()]
    param
    (
    )
}

<#
    .SYNOPSIS
        Sets the computer proxy settings in the registry.

    .PARAMETER Ensure
        Specifies if computer proxy settings should be set.
        Defaults to 'Present'.

    .PARAMETER ConnectionType
        Defines if the proxy settings should be configured
        for default connections, legacy connections or all
        connections. Defaults to 'All'.

    .PARAMETER EnableAutoDetection
        Enable automatic detection of the proxy settings. Defaults
        to 'False'.

    .PARAMETER EnableAutoConfiguration
        Use automatic configuration script for specifying proxy
        settings. Defaults to 'False'.

    .PARAMETER EnableManualProxy
        Use manual proxy server settings. Defaults to 'False'.

    .PARAMETER AutoConfigURL
        The URL of the automatic configuration script to specify
        the proxy settings. Should be specified if 'EnableAutoConfiguration'
        is 'True'.

    .PARAMETER ProxyServer
        The address and port of the manual proxy server to use.
        Should be specified if 'EnableManualProxy' is 'True'.

    .PARAMETER ProxyServerExceptions
        Bypass proxy server for addresses starting with addresses
        in this list.

    .PARAMETER ProxyServerBypassLocal
        Bypass proxy server for local addresses. Defaults to 'False'.
#>
function Set-ComputerProxySettings
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateSet('All','Default','Legacy')]
        [System.String]
        $ConnectionType = 'All',

        [Parameter()]
        [System.Boolean]
        $EnableAutoDetection = $false,

        [Parameter()]
        [System.Boolean]
        $EnableAutoConfiguration = $false,

        [Parameter()]
        [System.Boolean]
        $EnableManualProxy = $false,

        [Parameter()]
        [System.String]
        $AutoConfigURL,

        [Parameter()]
        [System.String]
        $ProxyServer,

        [Parameter()]
        [System.String[]]
        $ProxyServerExceptions = @(),

        [Parameter()]
        [System.Boolean]
        $ProxyServerBypassLocal = $false
    )

    if ($Ensure -eq 'Absent')
    {
        # Remove all the Proxy Settings
        Remove-ItemProperty `
            -Path "HKLM:\$($script:policyInternetSettingsRegistryKeyPath)" `
            -Name 'ProxySettingsPerUser' `
            -ErrorAction SilentlyContinue

        'WinHttpSettings','DefaultConnectionSettings','SavedLegacySettings' | Foreach-Object -Process {
            Remove-ItemProperty `
                -Path "HKLM:\$($script:connectionsRegistryKeyPath)" `
                -Name $_ `
                -ErrorAction SilentlyContinue
        }

        'ProxyEnable','ProxyServer','ProxyOverride','AutoConfigURL' | Foreach-Object -Process {
            Remove-ItemProperty `
                -Path "HKLM:\$($script:internetSettingsRegistryKeyPath)" `
                -Name $_ `
                -ErrorAction SilentlyContinue
        }

        'Autoconfig','Proxy' | Foreach-Object -Process {
            Remove-ItemProperty `
                -Path "HKLM:\$($script:controlPanelRegistryKeyPath)" `
                -Name $_ `
                -ErrorAction SilentlyContinue
        }
    }
    else
    {
        # Ensure per user proxy settings are disabled
        $null = [Microsoft.Win32.Registry]::SetValue("HKEY_LOCAL_MACHINE\$($script:policyInternetSettingsRegistryKeyPath)", 'ProxySettingsPerUser', '0', 'DWORD')

        <#
            Create the Byte Array that will be used to populate the
            DefaultConnectionSettings and SavedLegacySettings registry settings
        #>
        $proxySettings = @(0x46, 0x0, 0x0, 0x0, 0x8, 0x0, 0x0, 0x0, 0x1, 0x0, 0x0, 0x0)

        if ($EnableAutoDetection)
        {
            $proxySettings[8] = $proxySettings[8] + 8
        }

        if ($EnableManualProxy)
        {
            $proxySettings[8] = $proxySettings[8] + 2
        }

        if ($EnableAutoConfiguration)
        {
            $proxySettings[8] = $proxySettings[8] + 4
        }

        if ($PSBoundParameters.ContainsKey('ProxyServer'))
        {
            $proxySettings += @($ProxyServer.Length, 0x0, 0x0, 0x0)
            $proxySettings += [Byte[]][Char[]] $ProxyServer
        }
        else
        {
            $proxySettings += @(0x0, 0x0, 0x0, 0x0)
        }

        if ($ProxyServerBypassLocal -eq $true)
        {
            $ProxyServerExceptions += @('<local>')
        }

        if ($ProxyServerExceptions.Count -gt 0)
        {
            $ProxyServerExceptionsString = $ProxyServerExceptions -join ';'
            $proxySettings += @($ProxyServerExceptionsString.Length, 0x0, 0x0, 0x0)
            $proxySettings += [Byte[]][Char[]] $ProxyServerExceptionsString
        }
        else
        {
            $proxySettings += @(0x0, 0x0, 0x0, 0x0)
        }

        if ($PSBoundParameters.ContainsKey('AutoConfigURL'))
        {
            $proxySettings += @($AutoConfigURL.Length, 0x0, 0x0, 0x0)
            $proxySettings += [Byte[]][Char[]] $AutoConfigURL
        }

        $proxySettings += @(0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)
        $proxySettings += @(0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

        Remove-ItemProperty `
            -Path "HKLM:\$($script:connectionsRegistryKeyPath)" `
            -Name 'WinHttpSettings' `
            -ErrorAction SilentlyContinue

        if ($ConnectionType -in ('All','Default'))
        {
            Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                $($LocalizedData.WritingComputerProxySettingsMessage -f 'DefaultConnectionSettings')
                ) -join '')

            $null = [Microsoft.Win32.Registry]::SetValue("HKEY_LOCAL_MACHINE\$($script:connectionsRegistryKeyPath)", 'DefaultConnectionSettings', [Byte[]] $proxySettings, 'Binary')
        }

        if ($ConnectionType -in ('All','Legacy'))
        {
            Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                $($LocalizedData.WritingComputerProxySettingsMessage -f 'SavedLegacySettings')
                ) -join '')

            $null = [Microsoft.Win32.Registry]::SetValue("HKEY_LOCAL_MACHINE\$($script:connectionsRegistryKeyPath)", 'SavedLegacySettings', [Byte[]] $proxySettings, 'Binary')
        }
    }
}

Export-ModuleMember -function *-TargetResource
