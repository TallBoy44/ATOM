# Cisco FMC PowerShell Module

## Table of Contents

* [Description](#description) 
* [Release Information](#releases) 
* [Usage](#usage)
* [Functions](#functions)
    * [Authentication](#authentication-functions)
    * [General Functions](#general-functions)
    * [Sub-Interface Functions](#sub-interface-functions)
    * [Security Zone Functions](#security-zone-functions)
* [Examples](#examples)
* [Sub-Interface Model](#sub-interface-model)
* [Security Zone Model](#security-zone-model)
* [Additional Information](#additional-information)

## Description

This repository contains a PowerShell Module to help facilitate REST API calls to the Cisco FMC device. While there are many more REST API Endpoints avaiable, this module was designed in collaboration with the Networking Team to help fast track thier specific requests. 

> **WARNING**: There is a limit to the number of items returned by the Cisco FMC Rest API. By default, only **25** items will be returned. The JSON response will include a **Count** of all records. Functions that are expected to return more than 25 responses have built in logic query all of the records. This will result in multiple API calls to the Cisco FMC Device, this is expected behavior. 

This module will allow you to; 

- Authenticate with the Cisco FMC device
- Query avaiable Domains
- Query available Devices within the Domain
- List, Create and Remove Sub-Interfaces on the Device.
- List avaiable SecurityZones

*Any Issues or Bugs found while using this PowerShell Module will be tracked within GitHub Issues. The Issues will be worked on and included in future releases.*

## Releases

### Version 1.0.0

    - Initial Release of Powershell Module

### Version 1.0.1

    - Added Refresh Token Functionality
    - Updated 'New-SubInterface' to include SecurityZones

## Usage

To run this module you have two approaches:

### Approach 1

Clone/Download the `FMC.psm1` file to your local machine. Open **PowerShell** and navigate to the directory that the file is contained within. Run `Import-Module .\FMC.psm1` to import the module on your Workstation/System. **Note**: If you have an existing version of the Module, remove it with the following command `Remove-Module FMC`.

### Approach 2

View the raw content of `FMC.psm1` in this Repo. Copy the content to a blank **PowerShell ISE** window, highlight all the text and press the `Run Selection` button (F8). The console window embedded within **PowerShell ISE** now has access to these functions.

The first step for every use requires you to login to the Cisco FMC. Utilize the `Connect-FMC` command to generate the required Access/Refresh Tokens. After this initial command, the $TOKEN will be used with ALL other functions.

## Functions

### Authentication Functions

The Cisco FMC Device utilizes JSON Web Tokens (JWT) as its form of authentication and authorization. From a high level, this means you will obtain two "tokens" when you authenticate with the device; Access & Refresh Tokens. The **Access Token** is used for all authentication tasks and by default expires in **30 Minutes**. The **Refresh Token** is used to obtain a new **Access Token**. It can be used **3** times before a new login will be required. 

When performing queries against the device, you will pass the **Access Token** to the device within the header of the request. It is passed in the header `x-auth-access-token`. The **Refresh Token** can also be passed to the device during a query. This is passed in the header `x-auth-refresh-token`. 

#### Login to Cisco FMC

``` Powershell
Connect-FMC -Username 'username' -Password 'FakePassword'
```

This will return a Token PSObject contain both the Access & Refresh Tokens.

#### Refresh Access Token

``` Powershell
## REFRESH ACCESS TOKEN IF USED LESS THAN THREE TIMES
Refresh-Token -Token $TOKEN
```

Assuming the refresh token has been used less than three times, this will return the Token object with a newly updated Access Token.

### General Functions

#### List ALL Domains

``` Powershell
Get-Domains -Token $TOKEN
```

This will return a PSObject with All Avaiable Domains.

#### List ALL Devices within Domain

``` Powershell
Get-Devices -Token $TOKEN -DomainUUID -DomainUUID "90551459-a1b7-5565-d6d9-000000000002"
```

### Sub-Interface Functions

#### List ALL Sub-Interfaces within Device

``` Powershell
Get-SubInterfaces -DomainUUID "90551459-a1b7-5565-d6d9-000000000002" -DeviceUUID "c940d356-6d05-11e9-8e34-9d7b4e2f05c2" -Token $TOKEN`
```

This will return a PSObject with ALL Sub-Interfaces on the Specified Device & Domain (KC-INT-1).

#### Remove Sub-Interface from Device

##### SINGLE Sub-Interface

``` Powershell
Remove-SubInterfaces -DomainUUID "90551459-a1b7-5565-d6d9-000000000002" -DeviceUUID "c940d356-6d05-11e9-8e34-9d7b4e2f05c2" -Token $TOKEN -SubInterfaceID "00B77110-8CE2-0ed3-0000-167503976712"`
```

This command will remove the SINGLE Sub-Interface with the ID of '00B77110-8CE2-0ed3-0000-167503976712'

##### MULTIPLE Sub-Interfaces

``` Powershell
$SUBS = Get-SubInterfaces -DomainUUID "90551459-a1b7-5565-d6d9-000000000002" -DeviceUUID "c940d356-6d05-11e9-8e34-9d7b4e2f05c2" -Token $TOKEN
Remove-SubInterfaces -DomainUUID "90551459-a1b7-5565-d6d9-000000000002" -DeviceUUID "c940d356-6d05-11e9-8e34-9d7b4e2f05c2" -Token $TOKEN -SubInterfaces $SUBS
```

This command will remove all Sub-Interfaces that was returned from the `Get-SubInterfaces` command.

#### New Sub-Interface

This command will create new Sub-Interfaces on the device. It requires an input of a JSON file containing the Sub-Interfaces. The JSON file can be obtained using the `Get-SubInterfaces` command.

``` Powershell
New-SubInterface -FilePath .\subinterfaces.json -Token $TOKEN -DomainUUID "90551459-a1b7-5565-d6d9-000000000002" -DeviceUUID "c940d356-6d05-11e9-8e34-9d7b4e2f05c2" 
```

The above command will create a New Sub-Interface will the items specified in the JSON file.

``` Powershell
New-SubInterface -FilePath .\subinterfaces.json -Token $TOKEN -DomainUUID "90551459-a1b7-5565-d6d9-000000000002" -DeviceUUID "c940d356-6d05-11e9-8e34-9d7b4e2f05c2" -IncludeSecZone 
```

This command will use the `ifname` field and search for the corrosponding `securityZone`. If one is found, it will be added to the Sub-Interface.

### Security Zone Functions

#### List ALL Security Zones within Domain

``` Powershell
Get-SecurityZone -Token $TOKEN -DomainUUID "90551459-a1b7-5565-d6d9-000000000002"
```

This will return a PSObject with all the Security Zones contained within the specified Domain.

## Examples

#### Login to Cisco FMC

``` Powershell
$TOKEN = Connect-FMC -Username "api" -Password "FaKePaSsWoRd"
```

This will return a Token PSObject with two properties ($TOKEN.Token & $TOKEN.Refresh). Both properties contain the string values of thier respective tokens.

#### Find ALL Sub-Interfaces in KC and Remove

``` Powershell
## LOGIN
$TOKEN = Connect-FMC -Username "api" -Password "FaKePaSsWoRd"

## GET DOMAIN
$KC = Get-Domains -Token $TOKEN | Where-Object -FilterScript { $_.name -eq 'Global/KC' }

## GET FIREWALL DEVICE
$PRIMARY = Get-Devices -Token $TOKEN -DomainUUID $KC.uuid | Where-Object -FilterScript { $_.name -eq 'KC-INT-FW-1' }

## GET SUB-INTERFACES
$SUBS = Get-SubInterfaces -Token $TOKEN -DomainUUID $KC.uuid -DeviceUUID $PRIMARY.id

## REMOVE SUB-INTERFACES
Remove-SubInterfaces -Token $TOKEN -DomainUUID $KC.uuid -DeviceUUID $PRIMARY.id -SubInterfaces $SUBS
```

#### Search for Specific Sub-Interface within Domain & Device

``` Powershell
## LOGIN, GET DOMAIN & DEVICE, GET SUB-INTERFACES
$TOKEN = Connect-FMC -Username "api" -Password "FaKePaSsWoRd"
$KC = Get-Domains -Token $TOKEN | Where-Object -FilterScript { $_.name -eq 'Global/KC' }
$PRIMARY = Get-Devices -Token $TOKEN -DomainUUID $KC.uuid | Where-Object -FilterScript { $_.name -eq 'KC-INT-FW-1' }
$SUBS = Get-SubInterfaces -Token $TOKEN -DomainUUID $KC.uuid -DeviceUUID $PRIMARY.id

## SEARCH FOR SUB-INTERFACE
$SUBS | Where-Object -FilterScript { $_.ifname -eq 'SFTP' } | FT -Property *
```

#### Count all Sub-Interfaces within Domain & Device

``` Powershell
## LOGIN, DETERMINE DOMAIN & DEVICE
$TOKEN = Connect-FMC -Username "api" -Password "FaKePaSsWoRd"
$KC = Get-Domains -Token $TOKEN | Where-Object -FilterScript { $_.name -eq 'Global/KC' }
$PRIMARY = Get-Devices -Token $TOKEN -DomainUUID $KC.uuid | Where-Object -FilterScript { $_.name -eq 'KC-INT-FW-1' }

## GET SUB-INTERFACES
$SUBS = Get-SubInterfaces -Token $TOKEN -DomainUUID $KC.uuid -DeviceUUID $PRIMARY.id

## COUNT SUB-INTERFACES
$SUBS.Count
```

#### Display ALL Properties of Sub-Interface

``` Powershell
## LOGIN, DETERMINE DOMAIN & DEVICE
$TOKEN = Connect-FMC -Username "api" -Password "FaKePaSsWoRd"
$KC = Get-Domains -Token $TOKEN | Where-Object -FilterScript { $_.name -eq 'Global/KC' }
$PRIMARY = Get-Devices -Token $TOKEN -DomainUUID $KC.uuid | Where-Object -FilterScript { $_.name -eq 'KC-INT-FW-1' }

## GET SUB-INTERFACES
$SUBS = Get-SubInterfaces -Token $TOKEN -DomainUUID $KC.uuid -DeviceUUID $PRIMARY.id

## DISPLAY ALL PROPERTIES (CONSOLE)
$SUBS | FT -Property *

## DISPLAY ALL PROPERTIES (GUI WINDOW)
$SUBS | OGV
```

#### Export (Backup) All Sub-Interfaces within Domain & Device

Due to the default handling of JSON by PowerShell, `-Depth 10` needs to be added to the command to ensure all properties are outputed correctly. IPv4 is one of those properties that traverse several layers.

``` Powershell
## LOGIN, DETERMINE DOMAIN & DEVICE
$TOKEN = Connect-FMC -Username "api" -Password "FaKePaSsWoRd"
$KC = Get-Domains -Token $TOKEN | Where-Object -FilterScript { $_.name -eq 'Global/KC' }
$PRIMARY = Get-Devices -Token $TOKEN -DomainUUID $KC.uuid | Where-Object -FilterScript { $_.name -eq 'KC-INT-FW-1' }

## GET SUB-INTERFACES
$SUBS = Get-SubInterfaces -Token $TOKEN -DomainUUID $KC.uuid -DeviceUUID $PRIMARY.id

## EXPORT SUB-INTERFACES
$SUBS | ConvertTo-Json -Depth 10 | Out-File -FilePath "MyBackup.json"
```

#### Import (Restore) All Sub-Interfaces within Domain & Device

``` Powershell
## LOGIN, DETERMINE DOMAIN & DEVICE
$TOKEN = Connect-FMC -Username "api" -Password "FaKePaSsWoRd"
$KC = Get-Domains -Token $TOKEN | Where-Object -FilterScript { $_.name -eq 'Global/KC' }
$PRIMARY = Get-Devices -Token $TOKEN -DomainUUID $KC.uuid | Where-Object -FilterScript { $_.name -eq 'KC-INT-FW-1' }

## IMPORT SUB-INTERFACES (AS EXPORTED)
New-SubInterface -FilePath .\MyBackup.json -Token $TOKEN -DomainUUID $KC.uuid -DeviceUUID $PRIMARY.id 

## IMPORT SUB-INTERFACES (WITH ADDED SECURITY ZONS)
New-SubInterface -FilePath .\MyBackup.json -Token $TOKEN -DomainUUID $KC.uuid -DeviceUUID $PRIMARY.id -IncludeSecZone 
```

#### Obtain All Sub-Interfaces that belong to a specified Port-Channel

``` Powershell
## LOGIN, DETERMINE DOMAIN & DEVICE
$TOKEN = Connect-FMC -Username "api" -Password "FaKePaSsWoRd"
$KC = Get-Domains -Token $TOKEN | Where-Object -FilterScript { $_.name -eq 'Global/KC' }
$PRIMARY = Get-Devices -Token $TOKEN -DomainUUID $KC.uuid | Where-Object -FilterScript { $_.name -eq 'KC-INT-FW-1' }

## GET SUB-INTERFACES
$SUBS = Get-SubInterfaces -Token $TOKEN -DomainUUID $KC.uuid -DeviceUUID $PRIMARY.id

## SELECT PORT-CHANNEL 3
$PC3 = $SUBS | Where-Object -FilterScript { $_.name -eq 'Port-channel3' }

## DISPLAY ALL PROPERTIES (CONSOLE)
$PC3 | FT -Property *
```

#### Display ALL Properties of Sub-Interface

``` Powershell
## LOGIN, DETERMINE DOMAIN & DEVICE
$TOKEN = Connect-FMC -Username "api" -Password "FaKePaSsWoRd"
$KC = Get-Domains -Token $TOKEN | Where-Object -FilterScript { $_.name -eq 'Global/KC' }
$PRIMARY = Get-Devices -Token $TOKEN -DomainUUID $KC.uuid | Where-Object -FilterScript { $_.name -eq 'KC-INT-FW-1' }

## GET SUB-INTERFACES
$SUBS = Get-SubInterfaces -Token $TOKEN -DomainUUID $KC.uuid -DeviceUUID $PRIMARY.id

## DISPLAY ALL PROPERTIES (CONSOLE)
$SUBS | FT -Property *

## DISPLAY ALL PROPERTIES (GUI WINDOW)
$SUBS | OGV
```

## Sub-Interface Model

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

## Security Zone Model

Outlined below is an example SecurityZone with all its properties. When running the PowerShell function(s), there should be a one-to-one match of properties between JSON and the PSObject.

``` json
{
    "name": "Test2",
    "id": "Sec-zone-UUID-2",
    "type": "SecurityZone",
    "interfaceMode": "ASA",
    "interfaces": [
        {
            "type": "FPPhysicalInterface",
            "id": "Intf-UUID-3",
            "name": "outside"
        },
        {
            "type": "FPPhysicalInterface",
            "id": "Intf-UUID-4",
            "name": "inside"
        }
    ]
}
```

## Additional Information

#### Cisco Api Explorer (Swagger UI)
[Cisco FMC Api Explorer](https://172.16.9.59/api/api-explorer/)
