configuration Sample_NetworkTeam_RemoveTeam
{
    param
    (
        [string[]]$NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xNetworking

    Node $NodeName
    {
        NetworkTeam HostTeam
        {
          Name = 'HostTeam'
          Ensure = 'Absent'
        }
    }
 }

Sample_NetworkTeam_RemoveTeam
Start-DscConfiguration -Path Sample_NetworkTeam_RemoveTeam -Wait -Verbose -Force
