# Description

This resource is used to enable or disable LSO for specific protocols on a
network adapter.

The following table shows configuration overlap with [NetAdapterAdvancedProperty](https://github.com/dsccommunity/NetworkingDsc/wiki/NetAdapterAdvancedProperty).

| NetAdapterLso | | NetAdapterAdvancedProperty |
| -------------------- | ---- | ------------------------------------ |
| V1IPv4 | = | Not Available |
| IPv4 | = | *LsoV2IPv4 |
| IPv6 | = | *LsoV2IPv6 |
