# xDNSServerAddress
# DSC Resource that will set/test/get the current DNS Server Address,
# by accepting values among those given in xDNSServerAddress.schema.mof

#region LocalizedData

data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
GettingDNSServerAddressesMessage=Getting the DNS Server Addresses.
ApplyingDNSServerAddressesMessage=Applying the DNS Server Addresses.
DNSServersSetCorrectlyMessage=DNS Servers are set correctly.
DNSServersAlreadySetMessage=DNS Servers are already set correctly for Interface Alias : "{0}".
CheckingDNSServerAddressesMessage=Checking the DNS Server Addresses.
DNSServersNotCorrectMessage=DNS Servers are not correct. Expected "{0}", actual "{1}".
DNSServersHaveBeenSetCorrectlyMessage=DNS Servers were set to the desired state for Interface Alias : "{0}".
InterfaceNotAvailableError=Interface "{0}" is not available. Please select a valid interface and try again.
AddressFormatError=Address "{0}" is not in the correct format. Please correct the Address parameter in the configuration and try again.
AddressIPv4MismatchError=Address "{0}" is in IPv4 format, which does not match server address family {1}. Please correct either of them in the configuration and try again.
AddressIPv6MismatchError=Address "{0}" is in IPv6 format, which does not match server address family {1}. Please correct either of them in the configuration and try again.
'@
}

#endregion

#region Get-TargetResource function

function Get-TargetResource
{
<#
.SYNOPSIS 
Get current Node configuration.

.DESCRIPTION
Get the present list of DNS ServerAddress DSC Resource schema variables on the system
#>
    [OutputType([System.Collections.Hashtable])]
    [CmdletBinding()]
    param
    (        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String[]]$Address,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$InterfaceAlias,

        [Parameter(Mandatory)]
        [ValidateSet('IPv4', 'IPv6')]
        [String]$AddressFamily
    )
    
    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.GettingDNSServerAddressesMessage)
        ) -join '')

    $dnsClientServerAddresses = Get-NetAdapter -Name $InterfaceAlias | ForEach-Object { Get-DnsClientServerAddress -InterfaceAlias $_  -AddressFamily $AddressFamily }
    $returnValue = @{
        Address = $dnsClientServerAddresses.ServerAddresses
        AddressFamily = $AddressFamily
        InterfaceAlias = $InterfaceAlias
    }

    return $returnValue
}

#endregion

#region Set-TargetResource function

function Set-TargetResource
{
<#
.SYNOPSIS 
Set Node configuration to desired state.

.DESCRIPTION
Set a new Server Address in the current node
#>
    [CmdletBinding()]
    param
    (    
        # IP Address that has to be set    
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$Address,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [String]$AddressFamily,
        
        [Boolean]$Validate = $false
    )

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
        $($LocalizedData.ApplyingDNSServerAddressesMessage)
        ) -join '')

    # Get the current DNS Server Addresses based on the parameters given.
    # Interface Alias may return multiple when passed WildCard (*)
    $interfaceAliases = Get-NetAdapter -Name $InterfaceAlias
    foreach ($alias in $interfaceAliases.InterfaceAlias)
    {
        $currentAddress = (Get-DnsClientServerAddress `
                -InterfaceAlias $alias `
                -AddressFamily $AddressFamily `
                -ErrorAction Stop).ServerAddresses

        # Check if the Server addresses are the same as the desired addresses.
        [Boolean] $addressDifferent = (@(Compare-Object `
                -ReferenceObject $currentAddress `
                -DifferenceObject $Address `
                -SyncWindow 0).Length -gt 0)

        if ($addressDifferent)
        {
            # Set the DNS settings as well
            $Splat = @{
                InterfaceAlias = $alias
                Address = $Address
                Validate = $Validate
            }
            Set-DnsClientServerAddress @Splat `
                -ErrorAction Stop

            Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($LocalizedData.DNSServersHaveBeenSetCorrectlyMessage -f $alias)
                ) -join '' )
        }
        else 
        { 
            # Test will return true in this case
            Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($LocalizedData.DNSServersAlreadySetMessage -f $alias)
                ) -join '' )
        }
    }
}

#endregion

#region Test-TargetResource function

function Test-TargetResource
{
<#
.SYNOPSIS 
Test Node configuration is in desired state or not.

.DESCRIPTION
Test if the given Server Address is among the current node's Server Address collection.
#>
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param
    (        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$Address,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [String]$AddressFamily,
        
        [Boolean]$Validate = $false        
    )
    # Flag to signal whether settings are correct
    $desiredConfigurationMatch = New-Object System.Collections.Generic.List[Boolean];

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.CheckingDNSServerAddressesMessage)
        ) -join '' )

    # Validate the Settings passed
    Foreach ($ServerAddress in $Address) {       
        Test-ResourceProperty `
            -Address $ServerAddress `
            -AddressFamily $AddressFamily `
            -InterfaceAlias $InterfaceAlias
    }

    # Get the current DNS Server Addresses based on the parameters given.
    # Interface Alias may return multiple when passed WildCard (*)
    $interfaceAliases = Get-NetAdapter -Name $InterfaceAlias
    foreach ($alias in $interfaceAliases.Name)
    {
        $currentAddress = (Get-DnsClientServerAddress `
            -InterfaceAlias $alias `
            -AddressFamily $AddressFamily `
            -ErrorAction Stop).ServerAddresses

        # Check if the Server addresses are the same as the desired addresses.
        [Boolean] $addressDifferent = (@(Compare-Object `
                -ReferenceObject $currentAddress `
                -DifferenceObject $Address `
                -SyncWindow 0).Length -gt 0)

        if ($addressDifferent)
        {
            # Not return at once. To show user which interface is which status.
            $desiredConfigurationMatch.Add($false)
            Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($LocalizedData.DNSServersNotCorrectMessage) `
                    -f ($Address -join ','),($currentAddress -join ',')
                ) -join '' )
        }
        else 
        {
            $desiredConfigurationMatch.Add($true)
            # Test will return true in this case
            Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($LocalizedData.DNSServersSetCorrectlyMessage)
                ) -join '' )
        }
    }

    return !($desiredConfigurationMatch -contains $false)
}

#endregion

#region Helper functions

function Test-ResourceProperty
{
    # Function will check the Address details are valid and do not conflict with
    # Address family. Ensures interface exists.
    # If any problems are detected an exception will be thrown.
    [OutputType([Void])]
    [CmdletBinding()]
    param
    (
        [String]$Address,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$InterfaceAlias,

        [ValidateSet('IPv4', 'IPv6')]
        [String]$AddressFamily = 'IPv4'
    )

    # -Like means support wildcard for InterfaceAlias.
    # InterfaceAlias doesn't need to be exact name.
    if ( -not (Get-NetAdapter | Where-Object -Property Name -Like $InterfaceAlias))
    {
        $errorId = 'InterfaceNotAvailable'
        $errorCategory = [System.Management.Automation.ErrorCategory]::DeviceError
        $errorMessage = $($LocalizedData.InterfaceNotAvailableError) -f $InterfaceAlias
        $exception = New-Object -TypeName System.InvalidOperationException `
            -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    if ( -not ([System.Net.IPAddress]::TryParse($Address, [ref]0)))
    {
        $errorId = 'AddressFormatError'
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
        $errorMessage = $($LocalizedData.AddressFormatError) -f $Address
        $exception = New-Object -TypeName System.InvalidOperationException `
            -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    $detectedAddressFamily = ([System.Net.IPAddress]$Address).AddressFamily.ToString()
    if (($detectedAddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork.ToString()) `
        -and ($AddressFamily -ne 'IPv4'))
    {
        $errorId = 'AddressMismatchError'
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
        $errorMessage = $($LocalizedData.AddressIPv4MismatchError) -f $Address,$AddressFamily
        $exception = New-Object -TypeName System.InvalidOperationException `
            -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    if (($detectedAddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6.ToString()) `
        -and ($AddressFamily -ne 'IPv6'))
    {
        $errorId = 'AddressMismatchError'
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
        $errorMessage = $($LocalizedData.AddressIPv6MismatchError) -f $Address,$AddressFamily
        $exception = New-Object -TypeName System.InvalidOperationException `
            -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }
}

#endregion

# Functions to be exported
Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource
