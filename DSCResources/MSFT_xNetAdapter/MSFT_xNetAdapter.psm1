#######################################################################################
#  xNetAdapter : DSC Resource that will set/test/get the current IP
#  Address, by accepting values among those given in xNetAdapter.schema.mof
#######################################################################################

data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
GettingNetAdapetrMessage=Getting the NetAdapter.
ApplyingIPAddressMessage=Applying the NetAdapter.
NetAdapterSetStateMessage=NetAdapter was set to the desired state.
CheckingIPAddressMessage=Checking the NetAdapter.
IPAddressDoesNotMatchMessage=IP Address does NOT match desired state. Expected {0}, actual {1}.
IPAddressMatchMessage=IP Address is in desired state.
SubnetMaskDoesNotMatchMessage=Subnet mask does NOT match desired state. Expected {0}, actual {1}.
SubnetMaskMatchMessage=Subnet mask is in desired state.
DHCPIsNotDisabledMessage=DHCP is NOT disabled.
DHCPIsAlreadyDisabledMessage=DHCP is already disabled.
DHCPIsNotTestedMessage=DHCP status is ignored when Address Family is IPv6.
InterfaceNotAvailableError=Interface "{0}" is not available. Please select a valid interface and try again.
AddressFormatError=Address "{0}" is not in the correct format. Please correct the Address parameter in the configuration and try again.
AddressIPv4MismatchError=Address "{0}" is in IPv4 format, which does not match server address family {1}. Please correct either of them in the configuration and try again.
AddressIPv6MismatchError=Address "{0}" is in IPv6 format, which does not match server address family {1}. Please correct either of them in the configuration and try again.
NetAdapterNotFoundError=A NetAdapter matching the properties was not found. Please correct the properties and try again.
MultipleMatchingNetAdapterFound=Multiple matching NetAdapters where found for the properties. Please correct the properties or specify IgnoreMultipleMatchingAdapters to only use the first and try again.
'@
}

######################################################################################
# The Get-TargetResource cmdlet.
# This function will get the present list of IP Address DSC Resource schema variables on the system
######################################################################################
function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$PhysicalMediaType,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Status,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
        
        [Bool] $IgnoreMultipleMatchingAdapters
    )

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
        $($LocalizedData.GettingNetAdapetrMessage)
        ) -join '')

    Test-ResourceProperty @PSBoundParameters
    
    $Adapter  =  @(Get-NetAdapter | Where-Object {$_.PhysicalMediaType -eq $PhysicalMediaType -and $_.Status -eq $Status})
    
    if($Adapter.Count -gt 0)
    {
        $returnValue = @{
            PhysicalMediaType    = $PhysicalMediaType
            Status               = $Status
            Name                 = $Adapter[0].Name
            InterfaceAlias       = $InterfaceAlias
            MatchingAdapterCount = $Adapter.Count
        }
    }
    else
    {
        $returnValue = @{
            PhysicalMediaType    = $PhysicalMediaType
            Status               = $Status
            Name                 = $null
            InterfaceAlias       = $InterfaceAlias
            MatchingAdapterCount = 0
        }
    }

    $returnValue
}

######################################################################################
# The Set-TargetResource cmdlet.
# This function will set a new IP Address in the current node
######################################################################################
function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$PhysicalMediaType,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Status,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
        
        [Bool] $IgnoreMultipleMatchingAdapters
    )
    
    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.ApplyingNetAdapterMessage)
        ) -join '')

    # Get the current NetAdapter based on the parameters given.
    $getResults = Get-TargetResource @PSBoundParameters
    
    # Test if no adapter was found, if so return false
    if(!$getResults.Name)
    {
        $errorId = 'NetAdapterNotFound'
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
        $errorMessage = $LocalizedData.NetAdapterNotFoundError
        $exception = New-Object -TypeName System.InvalidOperationException `
            -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)        
    }
    elseif($getResults.MatchingAdapterCount -ne 1 -and !$IgnoreMultipleMatchingAdapters) # Test if a found adapter name mismatches, if so return false
    {
        $errorId = 'MultipleMatchingNetAdapterFound'
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
        $errorMessage = $LocalizedData.MultipleMatchingNetAdapterFound
        $exception = New-Object -TypeName System.InvalidOperationException `
            -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)        
    }
    else
    {
        Rename-NetAdapter -Name $getResults.Name -NewName $Name
    }

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
        $($LocalizedData.NetAdapterSetStateMessage)
        ) -join '' )
} # Set-TargetResource

######################################################################################
# The Test-TargetResource cmdlet.
# This will test if the given Network adapter is named correctly
######################################################################################
function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$PhysicalMediaType,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Status,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
        
        [Bool] $IgnoreMultipleMatchingAdapters
    )
    # Flag to signal whether settings are correct
    [Boolean] $desiredConfigurationMatch = $true

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
        $($LocalizedData.CheckingNetAdapterMessage)
        ) -join '')

    Test-ResourceProperty @PSBoundParameters

    # Get the current NetAdapter based on the parameters given.
    $getResults = Get-TargetResource @PSBoundParameters
    
    # Test if no adapter was found, if so return false
    if(!$getResults.Name)
    {
        $desiredConfigurationMatch = $false
    }
    elseif($getResults.Name -ne $Name) # Test if a found adapter name mismatches, if so return false
    {
        $desiredConfigurationMatch = $false
    }
    
    # return desiredConfigurationMatch     
    return $desiredConfigurationMatch
} # Test-TargetResource

#######################################################################################
#  Helper functions
#######################################################################################
function Test-ResourceProperty {
    # Function will check the IP Address details are valid and do not conflict with
    # Address family. Also checks the subnet mask and ensures the interface exists.
    # If any problems are detected an exception will be thrown.
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$PhysicalMediaType,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Status,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
        
        [Bool] $IgnoreMultipleMatchingAdapters
    )
    
    # TODO add any parameter validation

} # Test-ResourceProperty
#######################################################################################

#  FUNCTIONS TO BE EXPORTED
Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource
