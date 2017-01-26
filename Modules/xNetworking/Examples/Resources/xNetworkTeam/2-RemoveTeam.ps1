<#
    .EXAMPLE
    Removes the NIC Team for the listed interfacess.
#>
configuration Example
{
    param
    (
        [string[]] $NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xNetworking

    Node $NodeName
    {
        xNetworkTeam HostTeam
        {
            Name = 'HostTeam'
            Ensure = 'Absent'
            TeamMembers = 'NIC1','NIC2','NIC3'
        }
    }
 }
