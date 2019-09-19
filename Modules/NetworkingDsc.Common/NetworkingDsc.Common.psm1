<#
    .SYNOPSIS
        This function tests if a cmdlet exists.

    .PARAMETER Name
        The name of the cmdlet to check for.

    .PARAMETER Module
        The module containing the command.
#>
function Test-Command
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Module
    )

    return ($null -ne (Get-Command @PSBoundParameters -ErrorAction SilentlyContinue))
} # function Test-Command

<#
    .SYNOPSIS
        Tests if the current machine is a Nano server.
#>
function Test-IsNanoServer
{
    if (Test-Command -Name 'Get-ComputerInfo' -Module 'Microsoft.PowerShell.Management')
    {
        $computerInfo = Get-ComputerInfo

        if ('Server' -eq $computerInfo.OsProductType `
                -and 'NanoServer' -eq $computerInfo.OsServerLevel)
        {
            return $true
        }
    }

    return $false
}

<#
    .SYNOPSIS
        Retrieves the localized string data based on the machine's culture.
        Falls back to en-US strings if the machine's culture is not supported.

    .PARAMETER ResourceName
        The name of the resource as it appears before '.strings.psd1' of the localized string file.
        For example:
            For WindowsOptionalFeature: MSFT_WindowsOptionalFeature
            For Service: MSFT_ServiceResource
            For Registry: MSFT_RegistryResource
            For Helper: SqlServerDscHelper

    .PARAMETER ScriptRoot
        Optional. The root path where to expect to find the culture folder. This is only needed
        for localization in helper modules. This should not normally be used for resources.

    .NOTES
        To be able to use localization in the helper function, this function must
        be first in the file, before Get-LocalizedData is used by itself to load
        localized data for this helper module (see directly after this function).
#>
function Get-LocalizedData
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ResourceName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ScriptRoot
    )

    if (-not $ScriptRoot)
    {
        $dscResourcesFolder = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'DSCResources'
        $resourceDirectory = Join-Path -Path $dscResourcesFolder -ChildPath $ResourceName
    }
    else
    {
        $resourceDirectory = $ScriptRoot
    }

    $localizedStringFileLocation = Join-Path -Path $resourceDirectory -ChildPath $PSUICulture

    if (-not (Test-Path -Path $localizedStringFileLocation))
    {
        # Fallback to en-US
        $localizedStringFileLocation = Join-Path -Path $resourceDirectory -ChildPath 'en-US'
    }

    Import-LocalizedData `
        -BindingVariable 'localizedData' `
        -FileName "$ResourceName.strings.psd1" `
        -BaseDirectory $localizedStringFileLocation

    return $localizedData
}

<#
    .SYNOPSIS
        Creates and throws an invalid argument exception.

    .PARAMETER Message
        The message explaining why this error is being thrown.

    .PARAMETER ArgumentName
        The name of the invalid argument that is causing this error to be thrown.
#>
function New-InvalidArgumentException
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ArgumentName
    )

    $argumentException = New-Object -TypeName 'ArgumentException' `
        -ArgumentList @($Message, $ArgumentName)

    $newObjectParameters = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @($argumentException, $ArgumentName, 'InvalidArgument', $null)
    }

    $errorRecord = New-Object @newObjectParameters

    throw $errorRecord
}

<#
    .SYNOPSIS
        Creates and throws an invalid operation exception.

    .PARAMETER Message
        The message explaining why this error is being thrown.

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error.
#>
function New-InvalidOperationException
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    if ($null -eq $ErrorRecord)
    {
        $invalidOperationException = New-Object -TypeName 'InvalidOperationException' `
            -ArgumentList @($Message)
    }
    else
    {
        $invalidOperationException = New-Object -TypeName 'InvalidOperationException' `
            -ArgumentList @($Message, $ErrorRecord.Exception)
    }

    $newObjectParameters = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @(
            $invalidOperationException.ToString(),
            'MachineStateIncorrect',
            'InvalidOperation',
            $null
        )
    }

    $errorRecordToThrow = New-Object @newObjectParameters

    throw $errorRecordToThrow
}

<#
    .SYNOPSIS
        Creates and throws an object not found exception.

    .PARAMETER Message
        The message explaining why this error is being thrown.

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error.
#>
function New-ObjectNotFoundException
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    if ($null -eq $ErrorRecord)
    {
        $exception = New-Object -TypeName 'System.Exception' `
            -ArgumentList @($Message)
    }
    else
    {
        $exception = New-Object -TypeName 'System.Exception' `
            -ArgumentList @($Message, $ErrorRecord.Exception)
    }

    $newObjectParameters = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @(
            $exception.ToString(),
            'MachineStateIncorrect',
            'ObjectNotFound',
            $null
        )
    }

    $errorRecordToThrow = New-Object @newObjectParameters

    throw $errorRecordToThrow
}

<#
    .SYNOPSIS
        Creates and throws an invalid result exception.

    .PARAMETER Message
        The message explaining why this error is being thrown.

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error.
#>
function New-InvalidResultException
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    if ($null -eq $ErrorRecord)
    {
        $exception = New-Object -TypeName 'System.Exception' `
            -ArgumentList @($Message)
    }
    else
    {
        $exception = New-Object -TypeName 'System.Exception' `
            -ArgumentList @($Message, $ErrorRecord.Exception)
    }

    $newObjectParameters = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @(
            $exception.ToString(),
            'MachineStateIncorrect',
            'InvalidResult',
            $null
        )
    }

    $errorRecordToThrow = New-Object @newObjectParameters

    throw $errorRecordToThrow
}

<#
    .SYNOPSIS
        Creates and throws a not implemented exception.

    .PARAMETER Message
        The message explaining why this error is being thrown.

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error.
#>
function New-NotImplementedException
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    if ($null -eq $ErrorRecord)
    {
        $invalidOperationException = New-Object -TypeName 'NotImplementedException' `
            -ArgumentList @($Message)
    }
    else
    {
        $invalidOperationException = New-Object -TypeName 'NotImplementedException' `
            -ArgumentList @($Message, $ErrorRecord.Exception)
    }

    $newObjectParameters = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @(
            $invalidOperationException.ToString(),
            'MachineStateIncorrect',
            'NotImplemented',
            $null
        )
    }

    $errorRecordToThrow = New-Object @newObjectParameters

    throw $errorRecordToThrow
}

<#
    .SYNOPSIS
        Converts any IP Addresses containing CIDR notation filters in an array to use Subnet Mask
        notation.

    .PARAMETER Address
        The array of addresses to that need to be converted.
#>
function Convert-CIDRToSubhetMask
{
    [CmdletBinding()]
    [OutputType([ Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Address
    )

    $results = @()

    foreach ($entry in $Address)
    {
        if (-not $entry.Contains(':') -and -not $entry.Contains('-'))
        {
            $entrySplit = $entry -split '/'

            if (-not [String]::IsNullOrEmpty($entrySplit[1]))
            {
                # There was a / so this contains a Subnet Mask or CIDR
                $prefix = $entrySplit[0]
                $postfix = $entrySplit[1]

                if ($postfix -match '^[0-9]*$')
                {
                    # The postfix contains CIDR notation so convert this to Subnet Mask
                    $cidr = [System.Int32] $postfix
                    $subnetMaskInt64 = ([convert]::ToInt64(('1' * $cidr + '0' * (32 - $cidr)), 2))
                    $subnetMask = @(
                        ([math]::Truncate($subnetMaskInt64 / 16777216))
                        ([math]::Truncate(($subnetMaskInt64 % 16777216) / 65536))
                        ([math]::Truncate(($subnetMaskInt64 % 65536) / 256))
                        ([math]::Truncate($subnetMaskInt64 % 256))
                    )
                }
                else
                {
                    $subnetMask = $postfix -split '\.'
                }

                <#
                        Apply the Subnet Mast to the IP Address so that we end up with a correctly
                        masked IP Address that will match what the Firewall rule returns.
                #>
                $maskedIp = $prefix -split '\.'

                for ([System.Int32] $Octet = 0; $octet -lt 4; $octet++)
                {
                    $maskedIp[$Octet] = $maskedIp[$octet] -band $SubnetMask[$octet]
                }

                $entry = '{0}/{1}' -f ($maskedIp -join '.'), ($subnetMask -join '.')
            }
        }

        $results += $entry
    }

    return $results
} # Convert-CIDRToSubhetMask

<#
    .SYNOPSIS
        This function will find a network adapter based on the provided
        search parameters.

    .PARAMETER Name
        This is the name of network adapter to find.

    .PARAMETER PhysicalMediaType
        This is the media type of the network adapter to find.

    .PARAMETER Status
        This is the status of the network adapter to find.

    .PARAMETER MacAddress
        This is the MAC address of the network adapter to find.

    .PARAMETER InterfaceDescription
        This is the interface description of the network adapter to find.

    .PARAMETER InterfaceIndex
        This is the interface index of the network adapter to find.

    .PARAMETER InterfaceGuid
        This is the interface GUID of the network adapter to find.

    .PARAMETER DriverDescription
        This is the driver description of the network adapter.

    .PARAMETER InterfaceNumber
        This is the interface number of the network adapter if more than one
        are returned by the parameters.

    .PARAMETER IgnoreMultipleMatchingAdapters
        This switch will suppress an error occurring if more than one matching
        adapter matches the parameters passed.
#>
function Find-NetworkAdapter
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $PhysicalMediaType,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Up', 'Disconnected', 'Disabled')]
        [System.String]
        $Status = 'Up',

        [Parameter()]
        [System.String]
        $MacAddress,

        [Parameter()]
        [System.String]
        $InterfaceDescription,

        [Parameter()]
        [System.UInt32]
        $InterfaceIndex,

        [Parameter()]
        [System.String]
        $InterfaceGuid,

        [Parameter()]
        [System.String]
        $DriverDescription,

        [Parameter()]
        [System.UInt32]
        $InterfaceNumber = 1,

        [Parameter()]
        [System.Boolean]
        $IgnoreMultipleMatchingAdapters = $false
    )

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($script:localizedData.FindingNetAdapterMessage)
        ) -join '')

    $adapterFilters = @()

    if ($PSBoundParameters.ContainsKey('Name'))
    {
        $adapterFilters += @('($_.Name -eq $Name)')
    } # if

    if ($PSBoundParameters.ContainsKey('PhysicalMediaType'))
    {
        $adapterFilters += @('($_.PhysicalMediaType -eq $PhysicalMediaType)')
    } # if

    if ($PSBoundParameters.ContainsKey('Status'))
    {
        $adapterFilters += @('($_.Status -eq $Status)')
    } # if

    if ($PSBoundParameters.ContainsKey('MacAddress'))
    {
        $adapterFilters += @('($_.MacAddress -eq $MacAddress)')
    } # if

    if ($PSBoundParameters.ContainsKey('InterfaceDescription'))
    {
        $adapterFilters += @('($_.InterfaceDescription -eq $InterfaceDescription)')
    } # if

    if ($PSBoundParameters.ContainsKey('InterfaceIndex'))
    {
        $adapterFilters += @('($_.InterfaceIndex -eq $InterfaceIndex)')
    } # if

    if ($PSBoundParameters.ContainsKey('InterfaceGuid'))
    {
        $adapterFilters += @('($_.InterfaceGuid -eq $InterfaceGuid)')
    } # if

    if ($PSBoundParameters.ContainsKey('DriverDescription'))
    {
        $adapterFilters += @('($_.DriverDescription -eq $DriverDescription)')
    } # if

    if ($adapterFilters.Count -eq 0)
    {
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                $($script:localizedData.AllNetAdaptersFoundMessage)
            ) -join '')

        $matchingAdapters = @(Get-NetAdapter)
    }
    else
    {
        # Join all the filters together
        $adapterFilterScript = '(' + ($adapterFilters -join ' -and ') + ')'
        $matchingAdapters = @(Get-NetAdapter |
            Where-Object -FilterScript ([ScriptBlock]::Create($adapterFilterScript)))
    }

    # Were any adapters found matching the criteria?
    if ($matchingAdapters.Count -eq 0)
    {
        New-InvalidOperationException `
            -Message ($script:localizedData.NetAdapterNotFoundError)

        # Return a null so that ErrorAction SilentlyContinue works correctly
        return $null
    }
    else
    {
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                $($script:localizedData.NetAdapterFoundMessage -f $matchingAdapters.Count)
            ) -join '')

        if ($matchingAdapters.Count -gt 1)
        {
            if ($IgnoreMultipleMatchingAdapters)
            {
                # Was the number of matching adapters found matching the adapter number?
                if (($InterfaceNumber -gt 1) -and ($InterfaceNumber -gt $matchingAdapters.Count))
                {
                    New-InvalidOperationException `
                        -Message ($script:localizedData.InvalidNetAdapterNumberError `
                            -f $matchingAdapters.Count, $InterfaceNumber)

                    # Return a null so that ErrorAction SilentlyContinue works correctly
                    return $null
                } # if
            }
            else
            {
                New-InvalidOperationException `
                    -Message ($script:localizedData.MultipleMatchingNetAdapterFound `
                        -f $matchingAdapters.Count)

                # Return a null so that ErrorAction SilentlyContinue works correctly
                return $null
            } # if
        } # if
    } # if

    # Identify the exact adapter from the adapters that match
    $exactAdapter = $matchingAdapters[$InterfaceNumber - 1]

    $returnValue = [PSCustomObject] @{
        Name                 = $exactAdapter.Name
        PhysicalMediaType    = $exactAdapter.PhysicalMediaType
        Status               = $exactAdapter.Status
        MacAddress           = $exactAdapter.MacAddress
        InterfaceDescription = $exactAdapter.InterfaceDescription
        InterfaceIndex       = $exactAdapter.InterfaceIndex
        InterfaceGuid        = $exactAdapter.InterfaceGuid
        MatchingAdapterCount = $matchingAdapters.Count
    }

    return $returnValue
} # Find-NetworkAdapter

<#
    .SYNOPSIS
        Returns the DNS Client Server static address that are assigned to a network
        adapter. This is required because Get-DnsClientServerAddress always returns
        the currently assigned server addresses whether regardless if they were
        assigned as static or by DHCP.

        The only way that could be found to do this is to query the registry.

    .PARAMETER InterfaceAlias
        Alias of the network interface to get the static DNS Server addresses from.

    .PARAMETER AddressFamily
        IP address family.
#>
function Get-DnsClientServerStaticAddress
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [System.String]
        $AddressFamily
    )

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($script:localizedData.GettingDNSServerStaticAddressMessage) -f $AddressFamily, $InterfaceAlias
        ) -join '')

    # Look up the interface Guid
    $adapter = Get-NetAdapter `
        -InterfaceAlias $InterfaceAlias `
        -ErrorAction SilentlyContinue

    if (-not $adapter)
    {
        New-InvalidOperationException `
            -Message ($script:localizedData.InterfaceAliasNotFoundError `
                -f $InterfaceAlias)

        # Return null to support ErrorAction Silently Continue
        return $null
    } # if

    $interfaceGuid = $adapter.InterfaceGuid.ToLower()

    if ($AddressFamily -eq 'IPv4')
    {
        $interfaceRegKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$interfaceGuid\"
    }
    else
    {
        $interfaceRegKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\Interfaces\$interfaceGuid\"
    } # if

    $interfaceInformation = Get-ItemProperty `
        -Path $interfaceRegKeyPath `
        -ErrorAction SilentlyContinue
    $nameServerAddressString = $interfaceInformation.NameServer

    # Are any statically assigned addresses for this adapter?
    if ([System.String]::IsNullOrWhiteSpace($nameServerAddressString))
    {
        # Static DNS Server addresses not found so return empty array
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                $($script:localizedData.DNSServerStaticAddressNotSetMessage) -f $AddressFamily, $InterfaceAlias
            ) -join '')

        return $null
    }
    else
    {
        # Static DNS Server addresses found so split them into an array using comma
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                $($script:localizedData.DNSServerStaticAddressFoundMessage) -f $AddressFamily, $InterfaceAlias, $nameServerAddressString
            ) -join '')

        return @($nameServerAddressString -split ',')
    } # if
} # Get-DnsClientServerStaticAddress

<#
    .SYNOPSIS
    Returns the WINS Client Server static address that are assigned to a network
    adapter. The CIM class Win32_NetworkAdapterConfiguration unfortunately only supports
    the primary and secondary WINS server. The registry gives more flexibility.

    .PARAMETER InterfaceAlias
    Alias of the network interface to get the static WINS Server addresses from.
#>
function Get-WinsClientServerStaticAddress
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InterfaceAlias
    )

    Write-Verbose -Message ("$($MyInvocation.MyCommand): $($script:localizedData.GettingWinsServerStaticAddressMessage -f $InterfaceAlias)")

    # Look up the interface Guid
    $adapter = Get-NetAdapter -InterfaceAlias $InterfaceAlias -ErrorAction SilentlyContinue

    if (-not $adapter)
    {
        New-InvalidOperationException -Message ($script:localizedData.InterfaceAliasNotFoundError -f $InterfaceAlias)

        # Return null to support ErrorAction Silently Continue
        return $null
    }

    $interfaceGuid = $adapter.InterfaceGuid.ToLower()

    $interfaceRegKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_$interfaceGuid\"

    $interfaceInformation = Get-ItemProperty -Path $interfaceRegKeyPath -ErrorAction SilentlyContinue
    $nameServerAddressString = $interfaceInformation.NameServerList

    # Are any statically assigned addresses for this adapter?
    if (-not $nameServerAddressString)
    {
        # Static DNS Server addresses not found so return empty array
        Write-Verbose -Message ("$($MyInvocation.MyCommand): $($script:localizedData.WinsServerStaticAddressNotSetMessage -f $InterfaceAlias)")
        return $null
    }
    else
    {
        # Static DNS Server addresses found so split them into an array using comma
        Write-Verbose -Message ("$($MyInvocation.MyCommand): $($script:localizedData.WinsServerStaticAddressFoundMessage -f
        $InterfaceAlias, ($nameServerAddressString -join ','))")

        return $nameServerAddressString
    }
} # Get-WinsClientServerStaticAddress

<#
    .SYNOPSIS
    Sets the WINS Client Server static address on a network adapter. The CIM class
    Win32_NetworkAdapterConfiguration unfortunately only supports the primary and
    secondary WINS server. The registry gives more flexibility.

    .PARAMETER InterfaceAlias
    Alias of the network interface to set the static WINS Server addresses on.
#>
function Set-WinsClientServerStaticAddress
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.String[]]
        $Address
    )

    Write-Verbose -Message ("$($MyInvocation.MyCommand): $($script:localizedData.SettingWinsServerStaticAddressMessage -f $InterfaceAlias, ($Address -join ', '))")

    # Look up the interface Guid
    $adapter = Get-NetAdapter -InterfaceAlias $InterfaceAlias -ErrorAction SilentlyContinue

    if (-not $adapter)
    {
        New-InvalidOperationException -Message ($script:localizedData.InterfaceAliasNotFoundError -f $InterfaceAlias)
    }

    $interfaceGuid = $adapter.InterfaceGuid.ToLower()

    $interfaceRegKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_$interfaceGuid\"

    Set-ItemProperty -Path $interfaceRegKeyPath -Name NameServerList -Value $Address

} # Set-WinsClientServerStaticAddress

<#
    .SYNOPSIS
        Gets the IP Address prefix from a provided IP Address in CIDR notation.

    .PARAMETER IPAddress
        IP Address to get prefix for, can be in CIDR notation.

    .PARAMETER AddressFamily
        Address family for provided IP Address, defaults to IPv4.

#>
function Get-IPAddressPrefix
{
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipeline)]
        [System.String[]]
        $IPAddress,

        [Parameter()]
        [ValidateSet('IPv4', 'IPv6')]
        [System.String]
        $AddressFamily = 'IPv4'
    )

    process
    {
        foreach ($singleIP in $IPAddress)
        {
            $prefixLength = ($singleIP -split '/')[1]

            if (-not ($prefixLength) -and $AddressFamily -eq 'IPv4')
            {
                if ($singleIP.split('.')[0] -in (0..127))
                {
                    $prefixLength = 8
                }
                elseif ($singleIP.split('.')[0] -in (128..191))
                {
                    $prefixLength = 16
                }
                elseif ($singleIP.split('.')[0] -in (192..223))
                {
                    $prefixLength = 24
                }
            }
            elseif (-not ($prefixLength) -and $AddressFamily -eq 'IPv6')
            {
                $prefixLength = 64
            }

            [PSCustomObject]@{
                IPAddress    = $singleIP.split('/')[0]
                prefixLength = $prefixLength
            }
        }
    }
}

<#
    .SYNOPSIS
        Removes common parameters from a hashtable

    .DESCRIPTION
        This function serves the purpose of removing common parameters and option common parameters from a parameter hashtable

    .PARAMETER Hashtable
        The parameter hashtable that should be pruned
#>
function Remove-CommonParameter
{
    [OutputType([System.Collections.Hashtable])]
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Hashtable
    )

    $inputClone = $Hashtable.Clone()
    $commonParameters = [System.Management.Automation.PSCmdlet]::CommonParameters
    $commonParameters += [System.Management.Automation.PSCmdlet]::OptionalCommonParameters

    $Hashtable.Keys | Where-Object -FilterScript {
        $_ -in $commonParameters
    } | ForEach-Object -Process {
        $inputClone.Remove($_)
    }

    return $inputClone
}

<#
    .SYNOPSIS
        Tests the status of DSC resource parameters.

    .DESCRIPTION
        This function tests the parameter status of DSC resource parameters against the current values present on the system.

    .PARAMETER CurrentValues
        A hashtable with the current values on the system, obtained by e.g. Get-TargetResource.

    .PARAMETER DesiredValues
        The hashtable of desired values.

    .PARAMETER ValuesToCheck
        The values to check if not all values should be checked.

    .PARAMETER TurnOffTypeChecking
        Indicates that the type of the parameter should not be checked.

    .PARAMETER ReverseCheck
        Indicates that a reverse check should be done. The current and desired state are swapped for another test.

    .PARAMETER SortArrayValues
        If the sorting of array values does not matter, values are sorted internally before doing the comparison.
#>
function Test-DscParameterState
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $CurrentValues,

        [Parameter(Mandatory = $true)]
        [System.Object]
        $DesiredValues,

        [Parameter()]
        [System.String[]]
        $ValuesToCheck,

        [Parameter()]
        [switch]
        $TurnOffTypeChecking,

        [Parameter()]
        [switch]
        $ReverseCheck,

        [Parameter()]
        [switch]
        $SortArrayValues
    )

    $returnValue = $true

    if ($CurrentValues -is [Microsoft.Management.Infrastructure.CimInstance] -or
        $CurrentValues -is [Microsoft.Management.Infrastructure.CimInstance[]])
    {
        $CurrentValues = ConvertTo-HashTable -CimInstance $CurrentValues
    }

    if ($DesiredValues -is [Microsoft.Management.Infrastructure.CimInstance] -or
        $DesiredValues -is [Microsoft.Management.Infrastructure.CimInstance[]])
    {
        $DesiredValues = ConvertTo-HashTable -CimInstance $DesiredValues
    }

    $types = 'System.Management.Automation.PSBoundParametersDictionary', 'System.Collections.Hashtable', 'Microsoft.Management.Infrastructure.CimInstance'

    if ($DesiredValues.GetType().FullName -notin $types)
    {
        New-InvalidArgumentException `
            -Message ($script:localizedData.InvalidDesiredValuesError -f $DesiredValues.GetType().FullName) `
            -ArgumentName 'DesiredValues'
    }

    if ($CurrentValues.GetType().FullName -notin $types)
    {
        New-InvalidArgumentException `
            -Message ($script:localizedData.InvalidCurrentValuesError -f $CurrentValues.GetType().FullName) `
            -ArgumentName 'CurrentValues'
    }

    if ($DesiredValues -is [Microsoft.Management.Infrastructure.CimInstance] -and -not $ValuesToCheck)
    {
        New-InvalidArgumentException `
            -Message $script:localizedData.InvalidValuesToCheckError `
            -ArgumentName 'ValuesToCheck'
    }

    $desiredValuesClean = Remove-CommonParameter -Hashtable $DesiredValues

    if (-not $ValuesToCheck)
    {
        $keyList = $desiredValuesClean.Keys
    }
    else
    {
        $keyList = $ValuesToCheck
    }

    foreach ($key in $keyList)
    {
        $desiredValue = $desiredValuesClean.$key
        $currentValue = $CurrentValues.$key

        if ($desiredValue -is [Microsoft.Management.Infrastructure.CimInstance] -or
            $desiredValue -is [Microsoft.Management.Infrastructure.CimInstance[]])
        {
            $desiredValue = ConvertTo-HashTable -CimInstance $desiredValue
        }
        if ($currentValue -is [Microsoft.Management.Infrastructure.CimInstance] -or
            $currentValue -is [Microsoft.Management.Infrastructure.CimInstance[]])
        {
            $currentValue = ConvertTo-HashTable -CimInstance $currentValue
        }

        if ($null -ne $desiredValue)
        {
            $desiredType = $desiredValue.GetType()
        }
        else
        {
            $desiredType = @{
                Name = 'Unknown'
            }
        }

        if ($null -ne $currentValue)
        {
            $currentType = $currentValue.GetType()
        }
        else
        {
            $currentType = @{
                Name = 'Unknown'
            }
        }

        if ($currentType.Name -ne 'Unknown' -and $desiredType.Name -eq 'PSCredential')
        {
            # This is a credential object. Compare only the user name
            if ($currentType.Name -eq 'PSCredential' -and $currentValue.UserName -eq $desiredValue.UserName)
            {
                Write-Verbose -Message ($script:localizedData.MatchPsCredentialUsernameMessage -f $currentValue.UserName, $desiredValue.UserName)
                continue
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.NoMatchPsCredentialUsernameMessage -f $currentValue.UserName, $desiredValue.UserName)
                $returnValue = $false
            }

            # Assume the string is our username when the matching desired value is actually a credential
            if ($currentType.Name -eq 'string' -and $currentValue -eq $desiredValue.UserName)
            {
                Write-Verbose -Message ($script:localizedData.MatchPsCredentialUsernameMessage -f $currentValue, $desiredValue.UserName)
                continue
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.NoMatchPsCredentialUsernameMessage -f $currentValue, $desiredValue.UserName)
                $returnValue = $false
            }
        }

        if (-not $TurnOffTypeChecking)
        {
            if (($desiredType.Name -ne 'Unknown' -and $currentType.Name -ne 'Unknown') -and
                $desiredType.FullName -ne $currentType.FullName)
            {
                Write-Verbose -Message ($script:localizedData.NoMatchTypeMismatchMessage -f $key, $currentType.FullName, $desiredType.FullName)
                $returnValue = $false
                continue
            }
        }

        if ($currentValue -eq $desiredValue -and -not $desiredType.IsArray)
        {
            Write-Verbose -Message ($script:localizedData.MatchValueMessage -f $desiredType.FullName, $key, $currentValue, $desiredValue)
            continue
        }

        if ($desiredValuesClean.GetType().Name -in 'HashTable', 'PSBoundParametersDictionary')
        {
            $checkDesiredValue = $desiredValuesClean.ContainsKey($key)
        }
        else
        {
            $checkDesiredValue = Test-DscObjectHasProperty -Object $desiredValuesClean -PropertyName $key
        }

        if (-not $checkDesiredValue)
        {
            Write-Verbose -Message ($script:localizedData.MatchValueMessage -f $desiredType.FullName, $key, $currentValue, $desiredValue)
            continue
        }

        if ($desiredType.IsArray)
        {
            Write-Verbose -Message ($script:localizedData.TestDscParameterCompareMessage -f $key, $desiredType.FullName)

            if (-not $currentValue -and -not $desiredValue)
            {
                Write-Verbose -Message ($script:localizedData.MatchValueMessage -f $desiredType.FullName, $key, 'empty array', 'empty array')
                continue
            }
            elseif (-not $currentValue)
            {
                Write-Verbose -Message ($script:localizedData.NoMatchValueMessage -f $desiredType.FullName, $key, $currentValue, $desiredValue)
                $returnValue = $false
                continue
            }
            elseif ($currentValue.Count -ne $desiredValue.Count)
            {
                Write-Verbose -Message ($script:localizedData.NoMatchValueDifferentCountMessage -f $desiredType.FullName, $key, $currentValue.Count, $desiredValue.Count)
                $returnValue = $false
                continue
            }
            else
            {
                $desiredArrayValues = $desiredValue
                $currentArrayValues = $currentValue

                if ($SortArrayValues)
                {
                    $desiredArrayValues = $desiredArrayValues | Sort-Object
                    $currentArrayValues = $currentArrayValues | Sort-Object
                }

                for ($i = 0; $i -lt $desiredArrayValues.Count; $i++)
                {
                    if ($null -ne $desiredArrayValues[$i])
                    {
                        $desiredType = $desiredArrayValues[$i].GetType()
                    }
                    else
                    {
                        $desiredType = @{
                            Name = 'Unknown'
                        }
                    }

                    if ($null -ne $currentArrayValues[$i])
                    {
                        $currentType = $currentArrayValues[$i].GetType()
                    }
                    else
                    {
                        $currentType = @{
                            Name = 'Unknown'
                        }
                    }

                    if (-not $TurnOffTypeChecking)
                    {
                        if (($desiredType.Name -ne 'Unknown' -and $currentType.Name -ne 'Unknown') -and
                            $desiredType.FullName -ne $currentType.FullName)
                        {
                            Write-Verbose -Message ($script:localizedData.NoMatchElementTypeMismatchMessage -f $key, $i, $currentType.FullName, $desiredType.FullName)
                            $returnValue = $false
                            continue
                        }
                    }

                    if ($desiredArrayValues[$i] -ne $currentArrayValues[$i])
                    {
                        Write-Verbose -Message ($script:localizedData.NoMatchElementValueMismatchMessage -f $i, $desiredType.FullName, $key, $currentArrayValues[$i], $desiredArrayValues[$i])
                        $returnValue = $false
                        continue
                    }
                    else
                    {
                        Write-Verbose -Message ($script:localizedData.MatchElementValueMessage -f $i, $desiredType.FullName, $key, $currentArrayValues[$i], $desiredArrayValues[$i])
                        continue
                    }
                }

            }
        }
        elseif ($desiredType -eq [System.Collections.Hashtable] -and $currentType -eq [System.Collections.Hashtable])
        {
            $param = $PSBoundParameters
            $param.CurrentValues = $currentValue
            $param.DesiredValues = $desiredValue
            $null = $param.Remove('ValuesToCheck')

            if ($returnValue)
            {
                $returnValue = Test-DscParameterState @param
            }
            else
            {
                Test-DscParameterState @param | Out-Null
            }
            continue
        }
        else
        {
            if ($desiredValue -ne $currentValue)
            {
                Write-Verbose -Message ($script:localizedData.NoMatchValueMessage -f $desiredType.FullName, $key, $currentValue, $desiredValue)
                $returnValue = $false
            }
        }
    }

    if ($ReverseCheck)
    {
        Write-Verbose -Message $script:localizedData.StartingReverseCheck
        $reverseCheckParameters = $PSBoundParameters
        $reverseCheckParameters.CurrentValues = $DesiredValues
        $reverseCheckParameters.DesiredValues = $CurrentValues
        $null = $reverseCheckParameters.Remove('ReverseCheck')

        if ($returnValue)
        {
            $returnValue = Test-DscParameterState @reverseCheckParameters
        }
        else
        {
            $null = Test-DscParameterState @reverseCheckParameters
        }
    }

    Write-Verbose -Message ($script:localizedData.TestDscParameterResultMessage -f $returnValue)
    return $returnValue
}

<#
    .SYNOPSIS
        Tests of an object has a property

    .PARAMETER Object
        The object to test

    .PARAMETER PropertyName
        The property name
#>
function Test-DscObjectHasProperty
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Object,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PropertyName
    )

    if ($Object.PSObject.Properties.Name -contains $PropertyName)
    {
        return [System.Boolean] $Object.$PropertyName
    }

    return $false
}

<#
    .SYNOPSIS
        Converts a hashtable into a CimInstance array.

    .DESCRIPTION
        This function is used to convert a hashtable into MSFT_KeyValuePair objects. These are stored as an CimInstance array.
        DSC cannot handle hashtables but CimInstances arrays storing MSFT_KeyValuePair.

    .PARAMETER Hashtable
        A hashtable with the values to convert.

    .OUTPUTS
        An object array with CimInstance objects.
#>
function ConvertTo-CimInstance
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Collections.Hashtable]
        $Hashtable
    )

    process
    {
        foreach ($item in $Hashtable.GetEnumerator())
        {
            New-CimInstance -ClassName MSFT_KeyValuePair -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                Key   = $item.Key
                Value = if ($item.Value -is [array])
                {
                    $item.Value -join ','
                }
                else
                {
                    $item.Value
                }
            } -ClientOnly
        }
    }
}

<#
    .SYNOPSIS
        Converts CimInstances into a hashtable.

    .DESCRIPTION
        This function is used to convert a CimInstance array containing MSFT_KeyValuePair objects into a hashtable.

    .PARAMETER CimInstance
        An array of CimInstances or a single CimInstance object to convert.

    .OUTPUTS
        Hashtable
#>
function ConvertTo-HashTable
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyCollection()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $CimInstance
    )

    begin
    {
        $result = @{ }
    }

    process
    {
        foreach ($ci in $CimInstance)
        {
            $result.Add($ci.Key, $ci.Value)
        }
    }

    end
    {
        $result
    }
}

<#
.SYNOPSIS
    Returns a filter string for the net adapter CIM instances. Wildcards supported.

.PARAMETER InterfaceAlias
    Specifies the alias of a network interface. Supports the use of '*' or '%'.
#>
function Format-Win32NetworkAdapterFilterByNetConnectionID
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceAlias
    )

    if ($InterfaceAlias.Contains('*'))
    {
        $InterfaceAlias = $InterfaceAlias.Replace('*','%')
    }

    if ($InterfaceAlias.Contains('%'))
    {
        $operator = ' LIKE '
    }
    else
    {
        $operator = '='
    }

    $returnNetAdapaterFilter = 'NetConnectionID{0}"{1}"' -f $operator,$InterfaceAlias

    $returnNetAdapaterFilter
}

# Import Localization Strings
$script:localizedData = Get-LocalizedData `
    -ResourceName 'NetworkingDsc.Common' `
    -ScriptRoot $PSScriptRoot

Export-ModuleMember -Function @(
    'Test-Command',
    'Test-IsNanoServer',
    'New-InvalidArgumentException',
    'New-InvalidOperationException',
    'New-ObjectNotFoundException',
    'New-InvalidResultException',
    'New-NotImplementedException',
    'Get-LocalizedData',
    'Convert-CIDRToSubhetMask',
    'Find-NetworkAdapter',
    'Get-DnsClientServerStaticAddress',
    'Get-WinsClientServerStaticAddress',
    'Set-WinsClientServerStaticAddress',
    'Get-IPAddressPrefix',
    'Test-DscParameterState',
    'Test-DscObjectHasProperty'
    'ConvertTo-HashTable',
    'ConvertTo-CimInstance',
    'Format-Win32NetworkAdapterFilterByNetConnectionID'
)
