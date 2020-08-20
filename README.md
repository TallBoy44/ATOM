# Cisco FMC PowerShell Module

> **WARNING**: There is a limit to the number of items returned by the Cisco FMC Rest API. By default, only **25** items will be returned. The JSON response will include a **Count** of all records. In order to recieve more results than the default add `?limit=xxx` to the end of any query. Additionally, the max limit that can be returned is **1000**. In furture, these functions will incorporate logic to handle greater than 1000 results.

This repository contains a PowerShell Module to help facilitate REST API calls to the Cisco FMC device. While there are many more REST API Endpoints avaiable, this module was designed in collaboration with the Networking Team to help fast track thier specific requests.

## Table of Contents

1. Usage
2. Examples
3. Functions
4. Sub-Interface Model


## 1. Usage

To run this module you have two approaches:

### Approach 1

Clone/Download the `FMC.psm1` file to your local machine. Open **PowerShell** and navigate to the directory that the file is contained within. Run `Import-Module .\FMC.psm1` to import the module on your Workstation/System.

### Approach 2

View the raw content of `FMC.psm1` in this Repo. Copy the content to a black **PowerShell ISE** window, highlight all the text and press the `Run Selection` button (F8). The console window embedded within **PowerShell ISE** now has access to these functions.

The first step for every use requires you to login to the Cisco FMC. Utilize the `Login-FMC` command to generate the required Access/Refresh Tokens. After this initial command, the $TOKEN will be used with ALL other functions.

## 2. Examples

**Login to Cisco FMC**

`$TOKEN = Login-FMC -Username "api" -Password "FaKePaSsWoRd`

This will return a Token Object with two properties ($TOKEN.Token & $TOKEN.Refresh). Both properties contain the string values of thier respective tokens.

## 3. Functions

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

## 4. Sub-Interface Model

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
