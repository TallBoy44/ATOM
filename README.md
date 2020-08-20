# Cisco FMC PowerShell Module

This repository contains a PowerShell Module to help facilitate REST API calls to the Cisco FMC device. While there are many more REST API Endpoints avaiable, this module was designed in collaboration with the Networking Team to help fast track thier specific requests.

> **WARNING**: There is a limit to the number of items returned by the Cisco FMC Rest API. By default, only **25** items will be returned. The JSON response will include a **Count** of all records. In order to recieve more results than the default add `?limit=xxx` to the end of any query. Additionally, the max limit that can be returned is **1000**. In furture, these functions will incorporate logic to handle greater than 1000 results.

## Table of Contents

1. Usage
2. Functions
3. Examples
4. Sub-Interface Model


## 1. Usage

To run this module you have two approaches:

### Approach 1

Clone/Download the `FMC.psm1` file to your local machine. Open **PowerShell** and navigate to the directory that the file is contained within. Run `Import-Module .\FMC.psm1` to import the module on your Workstation/System.

### Approach 2

View the raw content of `FMC.psm1` in this Repo. Copy the content to a blank **PowerShell ISE** window, highlight all the text and press the `Run Selection` button (F8). The console window embedded within **PowerShell ISE** now has access to these functions.

The first step for every use requires you to login to the Cisco FMC. Utilize the `Login-FMC` command to generate the required Access/Refresh Tokens. After this initial command, the $TOKEN will be used with ALL other functions.

## 2. Functions

#### Login to Cisco FMC

``` Powershell
Login-FMC -Username 'username' -Password 'FakePassword'
```

This will return a Token PSObject contain both the Access & Refresh Tokens.

#### List ALL Domains

``` Powershell
Get-Domains -Token $TOKEN.Token
```

This will return a PSObject with All Avaiable Domains.

#### List ALL Devices within Domain

``` Powershell
Get-Devices -Token $TOKEN.Token -DomainUUID -DomainUUID "90551459-a1b7-5565-d6d9-000000000002"
```

#### List ALL Sub-Interfaces within Device

``` Powershell
Get-SubInterfaces -DomainUUID "90551459-a1b7-5565-d6d9-000000000002" -DeviceUUID "c940d356-6d05-11e9-8e34-9d7b4e2f05c2" -Token $TOKEN.Token`
```

This will return a PSObject with ALL Sub-Interfaces on the Specified Device & Domain (KC-INT-1).

#### Remove Sub-Interface from Device

##### Remove SINGLE Sub-Interface

``` Powershell
Remove-SubInterfaces -DomainUUID "90551459-a1b7-5565-d6d9-000000000002" -DeviceUUID "c940d356-6d05-11e9-8e34-9d7b4e2f05c2" -Token $TOKEN.Token -SubInterfaceID "00B77110-8CE2-0ed3-0000-167503976712"`
```

This command will remove the SINGLE Sub-Interface with the ID of '00B77110-8CE2-0ed3-0000-167503976712'

##### Remove MULTIPLE Sub-Interfaces

``` Powershell
$SUBS = Get-SubInterfaces -DomainUUID "90551459-a1b7-5565-d6d9-000000000002" -DeviceUUID "c940d356-6d05-11e9-8e34-9d7b4e2f05c2" -Token $TOKEN.Token
Remove-SubInterfaces -DomainUUID "90551459-a1b7-5565-d6d9-000000000002" -DeviceUUID "c940d356-6d05-11e9-8e34-9d7b4e2f05c2" -Token $TOKEN.Token -SubInterfaces $SUBS
```
This command will remove all Sub-Interfaces that was returned from the `Get-SubInterfaces` command.

## 3. Examples

#### Login to Cisco FMC

``` Powershell
$TOKEN = Login-FMC -Username "api" -Password "FaKePaSsWoRd`
```

This will return a Token PSObject with two properties ($TOKEN.Token & $TOKEN.Refresh). Both properties contain the string values of thier respective tokens.

#### Find ALL Sub-Interfaces in KC and Remove

``` Powershell
## LOGIN
$TOKEN = Login-FMC -Username "api" -Password "FaKePaSsWoRd`
## GET DOMAIN
$KC = Get-Domains -Token $TOKEN.Token | Where-Object -FilterScript { $_.name -eq 'Global/KC' }
## GET FIREWALL DEVICE
$PRIMARY = Get-Devices -Token $TOKEN.Token -DomainUUID $KC.uuid | Where-Object -FilterScript { $_.name -eq 'KC-INT-FW-1' }
## GET SUB-INTERFACES
$SUBS = Get-SubInterfaces -Token $TOKEN.Token -DomainUUID $KC.uuid -DeviceUUID $PRIMARY.id
## REMOVE SUB-INTERFACES
Remove-SubInterfaces -Token $TOKEN.Token -DomainUUID $KC.uuid -DeviceUUID $PRIMARY.id -SubInterfaces $SUBS
```

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
