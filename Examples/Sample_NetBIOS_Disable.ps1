configuration Sample_NetBIOS_Disabled
{
    param
    (
        [string[]]$NodeName = 'localhost'
    )

    Import-DscResource -ModuleName xNetworking

    node $NodeName 
    {
        NetBIOS DisableNetBIOS 
        {
            InterfaceAlias   = 'Ethernet'
            Setting = 'Disable'
        }
    }
}

Sample_NetBIOS_Disabled
Start-DscConfiguration -Path Sample_NetBIOS_Disabled -Wait -Verbose -Force 
