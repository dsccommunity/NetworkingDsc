#######################################################################################
#  xDNSServerAddress : DSC Resource that will set/test/get the current DNS Server
#  Address, by accepting values among those given in xDNSServerAddress.schema.mof
#######################################################################################
 


######################################################################################
# The Get-TargetResource cmdlet.
# This function will get the present list of DNS ServerAddress DSC Resource
# schema variables on the system
######################################################################################
function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
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
    
    Write-Verbose -Message "$($MyInvocation.MyCommand): Getting the DNS Server Addresses ..."

    $returnValue = @{
        Address = (Get-DnsClientServerAddress `
            -InterfaceAlias $InterfaceAlias `
            -AddressFamily $AddressFamily).ServerAddresses
        AddressFamily = $AddressFamily
        InterfaceAlias = $InterfaceAlias
    }

    $returnValue
}

######################################################################################
# The Set-TargetResource cmdlet.
# This function will set a new Server Address in the current node
######################################################################################
function Set-TargetResource
{
    param
    (    
        #IP Address that has to be set    
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

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
        'Applying the DNS Server Address ...'
        ) -join '')

    #Get the current DNS Server Addresses based on the parameters given.
    $PSBoundParameters.Remove('Address')
    $currentAddress = (Get-DnsClientServerAddress @PSBoundParameters `
        -ErrorAction Stop).ServerAddresses

    #Check if the Server addresses are the same as the desired addresses.
    [Boolean] $addressCompare = (Compare-Object `
            -ReferenceObject $currentAddress `
            -DifferenceObject $Address `
            -SyncWindow 0).Length -gt 0

    if ($addressCompare)
    {
        try
        {        
            # Set the DNS settings as well
            Set-DnsClientServerAddress `
                -InterfaceAlias $InterfaceAlias `
                -ServerAddresses $Address `
                -Validate
            Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                'DNS Servers have been set correctly.'
                ) -join '' )
        }
        catch
        {
            Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                "Error setting valid DNS Server addresses using InterfaceAlias $InterfaceAlias "
                "and AddressFamily $AddressFamily"
                ) -join '' )
            throw $_.Exception
        }
    }
    else 
    { 
        #Test will return true in this case
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            'DNS Servers are already set correctly.'
            ) -join '' )
    }
}

######################################################################################
# The Test-TargetResource cmdlet.
# This will test if the given Server Address is among the current node's Server Address collection
######################################################################################
function Test-TargetResource
{
    [OutputType([System.Boolean])]
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
    # Flag to signal whether settings are correct
    [Boolean] $desiredConfigurationMatch = $true

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        'Checking the DNS Server Address ...' 
        ) -join '' )

    #Validate the Settings passed
    Foreach ($ServerAddress in $Address) {       
        Test-ResourceProperty `
            -Address $ServerAddress `
            -AddressFamily $AddressFamily `
            -InterfaceAlias $InterfaceAlias
    }

    #Get the current DNS Server Addresses based on the parameters given.
    $currentAddress = (Get-DnsClientServerAddress `
        -InterfaceAlias $InterfaceAlias `
        -AddressFamily $AddressFamily `
        -ErrorAction Stop).ServerAddresses

    #Check if the Server addresses are the same as the desired addresses.
    if (@(Compare-Object `
        -ReferenceObject $currentAddress `
        -DifferenceObject $Address `
        -SyncWindow 0).Length -gt 0)
    {
        $desiredConfigurationMatch = $false
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            "DNS Servers are not correct. Expected $Address, actual $currentAddress." 
            ) -join '' )
    }
    else 
    { 
        #Test will return true in this case
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            'DNS Servers are set correctly.' 
            ) -join '' )
    }
    return $desiredConfigurationMatch
}

#######################################################################################
#  Helper functions
#######################################################################################
function Test-ResourceProperty
{
    # Function will check the Address details are valid and do not conflict with
    # Address family. Ensures interface exists.
    # If any problems are detected an exception will be thrown.
    [CmdletBinding()]
    param
    (
        [String]$Address,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$InterfaceAlias,

        [ValidateSet('IPv4', 'IPv6')]
        [String]$AddressFamily = 'IPv4'
    )

    if ( -not (Get-NetAdapter | Where-Object -Property Name -EQ $InterfaceAlias ))
    {
        throw ( @(
            "Interface $InterfaceAlias is not available. "
            'Please select a valid interface and try again'
            ) -join '' )
    }

    if ( -not ([System.Net.Ipaddress]::TryParse($Address, [ref]0)))
    {
        throw ( @(
            "Address $Address is not in the correct format. "
            'Please correct the Address parameter in the configuration and try again.'
            ) -join '' )
    }

    $detectedAddressFamily = ([System.Net.IPAddress]$Address).AddressFamily.ToString()
    if (($detectedAddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork.ToString()) `
        -and ($AddressFamily -ne 'IPv4'))
    {
        throw ( @(
            "Address $Address is in IPv4 format, which does not match "
            "server address family $AddressFamily. "
            'Please correct either of them in the configuration and try again.'
            ) -join '' )
    }

    if (($detectedAddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6.ToString()) `
        -and ($AddressFamily -ne 'IPv6'))
    {
        throw ( @(
            "Address $Address is in IPv6 format, which does not match "
            "server address family $AddressFamily. "
            'Please correct either of them in the configuration and try again'
            ) -join '' )
    }
} # Test-ResourceProperty
#######################################################################################

#  FUNCTIONS TO BE EXPORTED 
Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource
