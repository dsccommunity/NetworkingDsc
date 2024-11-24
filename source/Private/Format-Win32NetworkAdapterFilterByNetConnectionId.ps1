<#
.SYNOPSIS
    Returns a filter string for the net adapter CIM instances. Wildcards supported.

.PARAMETER InterfaceAlias
    Specifies the alias of a network interface. Supports the use of '*' or '%'.
#>
function Format-Win32NetworkAdapterFilterByNetConnectionId
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

    $returnNetAdapaterFilter = 'NetConnectionID{0}"{1}"' -f $operator, $InterfaceAlias

    return $returnNetAdapaterFilter
}
