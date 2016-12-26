@{
    ParameterList = @(
        @{ Name = 'Name';                Source = '$FirewallRule.Name';                             Type = 'String'                  }
        @{ Name = 'DisplayName';         Source = '$FirewallRule.DisplayName';                      Type = 'String'                  }
        @{ Name = 'Group';               Source = '$FirewallRule.Group';                            Type = 'String'                  }
        @{ Name = 'DisplayGroup';        Source = '$FirewallRule.DisplayGroup';                     Type = ''                        }
        @{ Name = 'Enabled';             Source = '$FirewallRule.Enabled';                          Type = 'String'                  }
        @{ Name = 'Action';              Source = '$FirewallRule.Action';                           Type = 'String'                  }
        @{ Name = 'Profile';             Source = '$firewallRule.Profile';                          Type = 'Array'; Delimiter = ', ' }
        @{ Name = 'Direction';           Source = '$FirewallRule.Direction';                        Type = 'String'                  }
        @{ Name = 'Description';         Source = '$FirewallRule.Description';                      Type = 'String'                  }
        @{ Name = 'RemotePort';          Source = '$properties.PortFilters.RemotePort';             Type = 'Array'                   }
        @{ Name = 'LocalPort';           Source = '$properties.PortFilters.LocalPort';              Type = 'Array'                   }
        @{ Name = 'Protocol';            Source = '$properties.PortFilters.Protocol';               Type = 'String'                  }
        @{ Name = 'Program';             Source = '$properties.ApplicationFilters.Program';         Type = 'String'                  }
        @{ Name = 'Service';             Source = '$properties.ServiceFilters.Service';             Type = 'String'                  }
        @{ Name = 'Authentication';      Source = '$properties.SecurityFilters.Authentication';     Type = 'String'                  }
        @{ Name = 'Encryption';          Source = '$properties.SecurityFilters.Encryption';         Type = 'String'                  }
        @{ Name = 'InterfaceAlias';      Source = '$properties.InterfaceFilters.InterfaceAlias';    Type = 'Array'                   }
        @{ Name = 'InterfaceType';       Source = '$properties.InterfaceTypeFilters.InterfaceType'; Type = 'String'                  }
        @{ Name = 'LocalAddress';        Source = '$properties.AddressFilters.LocalAddress';        Type = 'ArrayIP'                 }
        @{ Name = 'LocalUser';           Source = '$properties.SecurityFilters.LocalUser';          Type = 'String'                  }
        @{ Name = 'Package';             Source = '$properties.ApplicationFilters.Package';         Type = 'String'                  }
        @{ Name = 'Platform';            Source = '$firewallRule.Platform';                         Type = 'Array'                   }
        @{ Name = 'RemoteAddress';       Source = '$properties.AddressFilters.RemoteAddress';       Type = 'ArrayIP'                 }
        @{ Name = 'RemoteMachine';       Source = '$properties.SecurityFilters.RemoteMachine';      Type = 'String'                  }
        @{ Name = 'RemoteUser';          Source = '$properties.SecurityFilters.RemoteUser';         Type = 'String'                  }
        @{ Name = 'DynamicTransport';    Source = '$properties.PortFilters.DynamicTransport';       Type = 'String'                  }
        @{ Name = 'EdgeTraversalPolicy'; Source = '$FirewallRule.EdgeTraversalPolicy';              Type = 'String'                  }
        @{ Name = 'IcmpType';            Source = '$properties.PortFilters.IcmpType';               Type = 'Array'                   }
        @{ Name = 'LocalOnlyMapping';    Source = '$FirewallRule.LocalOnlyMapping';                 Type = 'Boolean'                 }
        @{ Name = 'LooseSourceMapping';  Source = '$FirewallRule.LooseSourceMapping';               Type = 'Boolean'                 }
        @{ Name = 'OverrideBlockRules';  Source = '$properties.SecurityFilters.OverrideBlockRules'; Type = 'Boolean'                 }
        @{ Name = 'Owner';               Source = '$FirewallRule.Owner';                            Type = 'String'                  }
    )
}
