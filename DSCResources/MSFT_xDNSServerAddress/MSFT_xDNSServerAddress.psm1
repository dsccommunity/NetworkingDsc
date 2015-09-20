<#######################################################################################
 #  xDNSServerAddress : DSC Resource that will set/test/get the current DNS Server
 #  Address, by accepting values among those given in xDNSServerAddress.schema.mof
 #######################################################################################>
 


######################################################################################
# The Get-TargetResource cmdlet.
# This function will get the present list of DNS ServerAddress DSC Resource schema variables on the system
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
        [ValidateSet("IPv4", "IPv6")]
        [String]$AddressFamily
    )
    
    Write-Verbose -Message "GET: Getting the DNS Server Addresses ..."

    $returnValue = @{
        Address = (Get-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -AddressFamily $AddressFamily).ServerAddresses
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
        [ValidateSet("IPv4", "IPv6")]
        [String]$AddressFamily
    )

    try
    {        
        Write-Verbose -Message "SET: Applying the DNS Server Address ..."

        #Validate the Settings passed
        Foreach ($ServerAddress in $Address) {       
            Validate-DNSServerAddress -Address $ServerAddress -AddressFamily $AddressFamily -InterfaceAlias $InterfaceAlias
        }

        #Get the current DNS Server Addresses based on the parameters given.
        $currentAddress = (Get-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -AddressFamily $AddressFamily -ErrorAction Stop).ServerAddresses

        #Check if the Server addresses are the same as the desired addresses.
        if(@(Compare-Object -ReferenceObject $currentAddress -DifferenceObject $Address -SyncWindow 0).Length -gt 0)
        {
            # Set the DNS settings as well
            Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $Address
            Write-Verbose -Message "SET: DNS Servers have been set correctly."
        }
        else 
        { 
            #Test will return true in this case
            Write-Verbose -Message "SET: DNS Servers are already set correctly."
        }
    }
    catch
    {
        Write-Verbose -Message ( @(
            "SET: Error setting valid DNS Server addresses using InterfaceAlias $InterfaceAlias and "
            "AddressFamily $AddressFamily"
            ) -join ""
        )
        throw $_.Exception
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
        [ValidateSet("IPv4", "IPv6")]
        [String]$AddressFamily
    )
    # Flag to signal whether settings are correct
    [Boolean]$requiresChanges = $false

    try
    {        
        Write-Verbose -Message "TEST: Checking the DNS Server Address ..."

        #Validate the Settings passed
        Foreach ($ServerAddress in $Address) {       
            Validate-DNSServerAddress -Address $ServerAddress -AddressFamily $AddressFamily -InterfaceAlias $InterfaceAlias
        }

        #Get the current DNS Server Addresses based on the parameters given.
        $currentAddress = (Get-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -AddressFamily $AddressFamily -ErrorAction Stop).ServerAddresses

        #Check if the Server addresses are the same as the desired addresses.
        if(@(Compare-Object -ReferenceObject $currentAddress -DifferenceObject $Address -SyncWindow 0).Length -gt 0)
        {
            $requiresChanges = $true
            Write-Verbose -Message "TEST: DNS Servers are not correct. Expected $Address, actual $currentAddress"
        }
        else 
        { 
            #Test will return true in this case
            Write-Verbose -Message "TEST: DNS Servers are set correctly."
        }
    }
    catch
    {
        Write-Verbose -Message ( @(
            "TEST: Error testing valid DNS Server addresses using InterfaceAlias $InterfaceAlias and "
            "AddressFamily $AddressFamily"
            ) -join ""
        )
        throw $_.Exception
    }
    return -not $requiresChanges
}

#######################################################################################
#  Helper functions
#######################################################################################
function Validate-DNSServerAddress {
# Function will check the Address details are valid and do not conflict with
# Address family. Ensures interface exists.
# If any problems are detected an exception will be thrown.
    [CmdLetBinding()]
    param
    (
        [String]$Address,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$InterfaceAlias,

        [ValidateSet("IPv4", "IPv6")]
        [String]$AddressFamily = "IPv4"
    )
    if(-not (Get-NetAdapter | Where-Object -Property Name -EQ $InterfaceAlias ))
    {
                throw "Interface $InterfaceAlias is not available. Please select a valid interface and try again"
    }
    if ($Address)
    {
        if(-not ([System.Net.Ipaddress]::TryParse($Address, [ref]0)))
        {
                throw ( @(
                    "Address *$Address* is not in the correct format. Please correct the Address "
                    "parameter in the configuration and try again."
                    ) -join ""
                )
        }
        if (([System.Net.IPAddress]$Address).AddressFamily.ToString() -eq [System.Net.Sockets.AddressFamily]::InterNetwork.ToString())
        {
            if ($AddressFamily -ne "IPv4")
            {
                throw ( @(
                    "Address $Address is in IPv4 format, which does not match server address family $AddressFamily. "
                    "Please correct either of them in the configuration and try again."
                    ) -join ""
                )
            }
        }
        else
        {
            if ($AddressFamily -ne "IPv6")
            {
                throw ( @(
                    "Address $Address is in IPv6 format, which does not match server address family $AddressFamily. "
                    "Please correct either of them in the configuration and try again"
                    ) -join ""
                )
            }
        }
    }
} # Validate-DNSServerAddress
#######################################################################################

#  FUNCTIONS TO BE EXPORTED 
Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource
