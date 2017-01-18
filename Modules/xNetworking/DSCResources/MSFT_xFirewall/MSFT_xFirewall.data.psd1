@{
    ParameterList = @(
        @{ Name = 'Name';                Source = 'Name';                               Variable = 'FirewallRule'; Type = 'String'                  }
        @{ Name = 'DisplayName';         Source = 'DisplayName';                        Variable = 'FirewallRule'; Type = 'String'                  }
        @{ Name = 'Group';               Source = 'Group';                              Variable = 'FirewallRule'; Type = 'String'                  }
        @{ Name = 'DisplayGroup';        Source = 'DisplayGroup';                       Variable = 'FirewallRule'; Type = ''                        }
        @{ Name = 'Enabled';             Source = 'Enabled';                            Variable = 'FirewallRule'; Type = 'String'                  }
        @{ Name = 'Action';              Source = 'Action';                             Variable = 'FirewallRule'; Type = 'String'                  }
        @{ Name = 'Profile';             Source = 'Profile';                            Variable = 'FirewallRule'; Type = 'Array'; Delimiter = ', ' }
        @{ Name = 'Direction';           Source = 'Direction';                          Variable = 'FirewallRule'; Type = 'String'                  }
        @{ Name = 'Description';         Source = 'Description';                        Variable = 'FirewallRule'; Type = 'String'                  }
        @{ Name = 'RemotePort';          Source = 'PortFilters.RemotePort';             Variable = 'properties';   Type = 'Array'                   }
        @{ Name = 'LocalPort';           Source = 'PortFilters.LocalPort';              Variable = 'properties';   Type = 'Array'                   }
        @{ Name = 'Protocol';            Source = 'PortFilters.Protocol';               Variable = 'properties';   Type = 'String'                  }
        @{ Name = 'Program';             Source = 'ApplicationFilters.Program';         Variable = 'properties';   Type = 'String'                  }
        @{ Name = 'Service';             Source = 'ServiceFilters.Service';             Variable = 'properties';   Type = 'String'                  }
        @{ Name = 'Authentication';      Source = 'SecurityFilters.Authentication';     Variable = 'properties';   Type = 'String'                  }
        @{ Name = 'Encryption';          Source = 'SecurityFilters.Encryption';         Variable = 'properties';   Type = 'String'                  }
        @{ Name = 'InterfaceAlias';      Source = 'InterfaceFilters.InterfaceAlias';    Variable = 'properties';   Type = 'Array'                   }
        @{ Name = 'InterfaceType';       Source = 'InterfaceTypeFilters.InterfaceType'; Variable = 'properties';   Type = 'String'                  }
        @{ Name = 'LocalAddress';        Source = 'AddressFilters.LocalAddress';        Variable = 'properties';   Type = 'ArrayIP'                 }
        @{ Name = 'LocalUser';           Source = 'SecurityFilters.LocalUser';          Variable = 'properties';   Type = 'String'                  }
        @{ Name = 'Package';             Source = 'ApplicationFilters.Package';         Variable = 'properties';   Type = 'String'                  }
        @{ Name = 'Platform';            Source = 'Platform';                           Variable = 'FirewallRule'; Type = 'Array'                   }
        @{ Name = 'RemoteAddress';       Source = 'AddressFilters.RemoteAddress';       Variable = 'properties';   Type = 'ArrayIP'                 }
        @{ Name = 'RemoteMachine';       Source = 'SecurityFilters.RemoteMachine';      Variable = 'properties';   Type = 'String'                  }
        @{ Name = 'RemoteUser';          Source = 'SecurityFilters.RemoteUser';         Variable = 'properties';   Type = 'String'                  }
        @{ Name = 'DynamicTransport';    Source = 'PortFilters.DynamicTransport';       Variable = 'properties';   Type = 'String'                  }
        @{ Name = 'EdgeTraversalPolicy'; Source = 'EdgeTraversalPolicy';                Variable = 'FirewallRule'; Type = 'String'                  }
        @{ Name = 'IcmpType';            Source = 'PortFilters.IcmpType';               Variable = 'properties';   Type = 'Array'                   }
        @{ Name = 'LocalOnlyMapping';    Source = 'LocalOnlyMapping';                   Variable = 'FirewallRule'; Type = 'Boolean'                 }
        @{ Name = 'LooseSourceMapping';  Source = 'LooseSourceMapping';                 Variable = 'FirewallRule'; Type = 'Boolean'                 }
        @{ Name = 'OverrideBlockRules';  Source = 'SecurityFilters.OverrideBlockRules'; Variable = 'properties';   Type = 'Boolean'                 }
        @{ Name = 'Owner';               Source = 'Owner';                              Variable = 'FirewallRule'; Type = 'String'                  }
    )
}
