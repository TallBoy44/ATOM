# Cisco FMC PowerShell Module

*For Brandon Thomas*

> **WARNING**: There is a limit to the number of items returned by the Cisco FMC Rest API. By default, only **25** items will be returned. The JSON response will include a **Count** of all records. In order to recieve more results than the default add `?limit=xxx` to the end of any query. Additionally, the max limit that can be returned is **1000**. In furture, these functions will incorporate logic to handle greater than 1000 results.

## Description

placeholder text

## Usage

placeholder text

## Examples

placeholder text

## Functions

**Login to Cisco FMC**

`Login-FMC`

**List Domains on FMC**

`Get-Domains`

**List ALL Devices within Domain**

`Get-Devices`

**List ALL SubInterfaces within Device**

`Get-SubInterfaces`

**Remove SubInterface from Device**

`Remove-SubInterfaces`

## Subnet Interface Model

Outlined below is an example SubInterface with all its properties. When running the PowerShell function(s), there should be a one-to-one match of properties between JSON and the PSObject.

```json
{
    "type": "SubInterface",
    "vlanId": 26,
    "subIntfId": 26,
    "enabled": false,
    "MTU": 9084,
    "mode": "NONE",
    "managementOnly": false,
    "securityZone": {
        "id": "88d5a09a-3e23-11ea-9176-2afd1ef78c78",
        "type": "SecurityZone"
    },
    "enableSGTPropagate": true,
    "enableAntiSpoofing": false,
    "fragmentReassembly": false,
    "ipv6": {
        "enableIPV6": false,
        "enforceEUI64": false,
        "enableAutoConfig": false,
        "enableDHCPAddrConfig": false,
        "enableDHCPNonAddrConfig": false,
        "dadAttempts": 1,
        "nsInterval": 1000,
        "reachableTime": 0,
        "enableRA": true,
        "raLifeTime": 1800,
        "raInterval": 200
    },
    "ipv4": {
        "static": {
            "address": "192.168.0.1",
            "netmask": "255.255.255.0"
        }
    },
    "ifname": "STORAGE_MGT",
    "name": "Port-channel3",
    "id": "00B77110-8CE2-0ed3-0000-167503976712",
    "metadata": {
        "timestamp": 1597843956643,
        "domain": {
            "name": "Global \\ KC",
            "id": "90551459-a1b7-5565-d6d9-000000000002",
            "type": "Domain"
        },
        "state": "COMMITTED"
    }
}
```
