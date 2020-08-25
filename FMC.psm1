#####################################
##  CISCO FMC - POWERSHELL MODULE  ##
#####################################

<#
------------------------------
    FILE DETAILS
------------------------------

Filename: FMC.psm1
Version: 1.0.1
Author: Peter Keech (NexGen Data Systems, Inc.)
Purpose: Configure Cisco FMC Device
Requirements: N/a
Paraments: FMC Credentials

------------------------------
    CHANGE LOG
------------------------------

v1.0.0
    - Initial Release of Module
v1.0.1
    - Added Refresh Token
    - Updated 'New-SubInterface' to include SecurityZones

#>

## ALLOW FOR SELF-SIGNED CERTIFICATE
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

## ----- AUTHENTICATION -----

## FUNCTION: LOGIN TO FMC
function Connect-FMC {
    ## DEFINE PARAMETERS
    param(
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string]$URL = "https://172.16.9.59/api/fmc_platform/v1/auth/generatetoken",

        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        $Username,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        $Password
    )

    BEGIN {
        ## DEFINE HEADERS
        $CREDS = "$($Username):$($Password)"
        $BASIC_AUTH = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($CREDS))
        $BASIC_AUTH = "Basic $($BASIC_AUTH)"
        $HEADERS = @{ Authorization = $BASIC_AUTH }

        ## DEFINE CLASS
        class Token {
            [string]$Access
            [string]$Refresh
            [int]$Count = 0
        }

        ## CREATE OBJECT
        $TOKEN = New-Object Token
    }

    PROCESS {
        ## ATTEMPT TO QUERY FMC API
        try{
            $RESPONSE = Invoke-WebRequest -Uri $URL -Method Post -Headers $HEADERS
        }
        catch{
            Write-Warning "Unable to connect to FMC API Endpoint ($($URL))."
            Write-Warning "Status Code: $($_.Exception.Response.StatusCode.Value__)"
            Write-Warning "Error Message: $($_.Exception.Message)"
            break
        }        
    }

    END {
        ## RETURN TOKEN
        $TOKEN.Access = $RESPONSE.Headers.'X-auth-access-token'
        $TOKEN.Refresh = $RESPONSE.Headers.'X-auth-refresh-token'
        
        return $TOKEN
    }

}

## FUNCTION: REFRESH TOKEN
function Refresh-Token {
    ## DEFINE PARAMETERS
    param(
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string]$URL = "https://172.16.9.59/api/fmc_platform/v1/auth/refreshtoken",

        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        $Token
    )
    
    BEGIN {
        ## VERIFY TOKEN HASN'T BEEN REFRESHED MORE THAN 3 TIMES
        if ($Token.Count -ge 3){
            Write-Warning "Token has been refreshed more than 3 times. Please Connect to FMC again"
            break
        }

        ## DEFINE HEADERS
        $HEADERS = @{
            'x-auth-access-token' = "$($Token.Access)"
            'x-auth-refresh-token' = "$($Token.Refresh)"
        }

    }
    
    PROCESS {
        ## ATTEMPT TO QUERY FMC API
        try{
            $RESPONSE = Invoke-WebRequest -Uri $URL -Method Post -Headers $HEADERS
        }
        catch{
            Write-Warning "Unable to connect to FMC API Endpoint ($($URL))."
            Write-Warning "Status Code: $($_.Exception.Response.StatusCode.Value__)"
            Write-Warning "Error Message: $($_.Exception.Message)"
            break
        }  

        ## UPDATE TOKEN OBJECT
        $TOKEN.Access = $RESPONSE.Headers.'X-auth-access-token'
        $TOKEN.Refresh = $RESPONSE.Headers.'X-auth-refresh-token'
        $TOKEN.Count += 1
    
    }

    END {
        ## RETURN NEW TOKEN OBJECT
        return $TOKEN
    }

}

## ----- GENERAL -----

## FUNCTION: GET FMC DOMAINS
function Get-Domains {
    ## DEFINE PARAMETERS
    param(
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string]$URL = "https://172.16.9.59/api/fmc_platform/v1/info/domain",

        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        $Token
    )

    BEGIN {
        ## DEFINE HEADERS
        $HEADERS = @{
            'x-auth-access-token' = "$($Token.Access)"
            'x-auth-refresh-token' = "$($Token.Refresh)"
        }
    }
    
    PROCESS {
        ## ATTEMPT TO QUERY FMC API
        try{
            $RESPONSE = Invoke-WebRequest -Uri $URL -Method Get -Headers $HEADERS
        }
        catch{
            Write-Warning "Unable to connect to FMC API Endpoint ($($URL))."
            Write-Warning "Status Code: $($_.Exception.Response.StatusCode.Value__)"
            Write-Warning "Error Message: $($_.Exception.Message)"
            break
        } 
    }

    END {
        ## CONVERT RESPONSE TO OBJECT
        $RESULTS = ConvertFrom-Json $RESPONSE.Content

        ## RETURN RESULTS
        return $RESULTS.items | select uuid, type, name
    }
}

## FUNCTION: QUERY FMC DEVICES
function Get-Devices {
    ## DEFINE PARAMETERS
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [string]$DomainUUID,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        $Token
    )

    BEGIN {
        ## DEFINE HEADERS
        $HEADERS = @{
            'x-auth-access-token' = "$($Token.Access)"
            'x-auth-refresh-token' = "$($Token.Refresh)"
        }

        ## DEFINE URL
        $URL = "https://172.16.9.59/api/fmc_config/v1/domain/$($DomainUUID)/devices/devicerecords"
    }
    
    PROCESS {
        ## ATTEMPT TO QUERY FMC API
        try{
            $RESPONSE = Invoke-WebRequest -Uri $URL -Method Get -Headers $HEADERS
        }
        catch{
            Write-Warning "Unable to connect to FMC API Endpoint ($($URL))."
            Write-Warning "Status Code: $($_.Exception.Response.StatusCode.Value__)"
            Write-Warning "Error Message: $($_.Exception.Message)"
            break
        } 
    }

    END {
        ## CONVERT RESPONSE TO OBJECT
        $RESULTS = ConvertFrom-Json $RESPONSE.Content

        ## RETURN RESULTS
        return $RESULTS.items | select id, type, name
    }

}


## ----- SUB-INTERFACES -----

## FUNCTION: COUNT NUMBER OF SUB-INTERFACES ON DEVICE
function Count-SubInterfaces {
## DEFINE PARAMETERS
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [string]$DomainUUID,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [string]$DeviceUUID,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        $Token
    )

    BEGIN {
        ## DEFINE HEADERS
        $HEADERS = @{
            'x-auth-access-token' = "$($Token.Access)"
            'x-auth-refresh-token' = "$($Token.Refresh)"
        }

        ## DEFINE URL
        $URL = "https://172.16.9.59/api/fmc_config/v1/domain/$($DomainUUID)/devices/devicerecords/$($DeviceUUID)/subinterfaces"
    }
    
    PROCESS {
        ## ATTEMPT TO QUERY FMC API FOR SUBINTERFACE COUNT
        try{
            $RESPONSE = Invoke-WebRequest -Uri $URL -Method Get -Headers $HEADERS
            $COUNT = ($RESPONSE.Content | ConvertFrom-Json).paging.count
        }
        catch{
            Write-Warning "Unable to connect to FMC API Endpoint ($($URL))."
            Write-Warning "Status Code: $($_.Exception.Response.StatusCode.Value__)"
            Write-Warning "Error Message: $($_.Exception.Message)"
            break
        }
    }

    END {
        ## RETURN COUNT
        return $COUNT
    }
}

## FUNCTION: QUERY SUB-INTERFACES ON DEVICE
function Get-SubInterfaces {
    ## DEFINE PARAMETERS
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [string]$DomainUUID,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [string]$DeviceUUID,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        $Token
    )

    BEGIN {
        ## DEFINE HEADERS
        $HEADERS = @{
            'x-auth-access-token' = "$($Token.Access)"
            'x-auth-refresh-token' = "$($Token.Refresh)"
        }

        ## DEFINE URL
        $URL = "https://172.16.9.59/api/fmc_config/v1/domain/$($DomainUUID)/devices/devicerecords/$($DeviceUUID)/subinterfaces?limit=200&expanded=true"
    }
    
    PROCESS {
        ## DEFINE NEW RESULTS OBJECT
        $RESULTS = @()

        ## DEFINE NEXT FLAG
        [bool]$NEXT = $true

        ## ATTEMPT TO QUERY FMC API FOR SUB INTERFACES
        try{
            ## LOOP THROUGH ALL RECORDS
            while($NEXT -eq $true){
                ## QUERY API
                $RESPONSE = Invoke-WebRequest -Uri $URL -Method Get -Headers $HEADERS

                ## CONVERT TO PSOBJECT
                $CONTENT = $RESPONSE.Content | ConvertFrom-Json

                ## ADD RECORDS TO ARRAY
                $RESULTS += $CONTENT.items

                ## CHECK FOR NEXT LINK
                if ([bool]($CONTENT.paging.PSObject.Properties.name -match 'next') -eq $false){
                    ## CANCEL LOOP
                    $NEXT = $false
                } else {
                    ## UPDATE URL
                    $URL = $CONTENT.paging.next[0]
                }

            }
        }
        catch{
            Write-Warning "Unable to connect to FMC API Endpoint ($($URL))."
            Write-Warning "Status Code: $($_.Exception.Response.StatusCode.Value__)"
            Write-Warning "Error Message: $($_.Exception.Message)"
            break
        } 
    }

    END {
        ## RETURN RESULTS
        return $RESULTS | select * -ExcludeProperty links, metadata
    }

}

## FUNCTION: DELETE SUB-INTERFACES
function Remove-SubInterface {
    ## DEFINE PARAMETERS
    [CmdletBinding(DefaultParameterSetName='SubInterfaceID')]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [string]$DomainUUID,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [string]$DeviceUUID,

        [Parameter(Mandatory=$true, ParameterSetName='SubInterfaceID')]
        [ValidateNotNullorEmpty()] 
        [string]$SubInterfaceID,

        [Parameter(Mandatory=$true, ParameterSetName='SubInterfaces')]
        [ValidateNotNullorEmpty()] 
        [array]$SubInterfaces = $null,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        $Token
    )

    BEGIN {
        ## DEFINE HEADERS
        $HEADERS = @{
            'x-auth-access-token' = "$($Token.Access)"
            'x-auth-refresh-token' = "$($Token.Refresh)"
        }
    }
    
    PROCESS {
        ## DETERMINE SINGLE UUID vs. MULTIPLE
        if($PSBoundParameters.ContainsKey('SubInterfaceID') -eq $true) {
            ## CREATE URL TO REMOVE SINGLE SUBINTERFACE
            $URL = "https://172.16.9.59/api/fmc_config/v1/domain/$($DomainUUID)/devices/devicerecords/$($DeviceUUID)/subinterfaces/$($SubInterfaceID)"
            
            ## VERBOSE: DELETING SUBINTERFACE
            Write-Verbose "Attempting to Delete SubInterface ($($SubInterfaceID) ..."

            ## ATTEMPT TO REMOVE SUBINTERFACE
            try{
                $RESPONSE = Invoke-WebRequest -Uri $URL -Method Delete -Headers $HEADERS
            }
            catch{
                Write-Warning "Unable to connect to FMC API Endpoint ($($URL))."
                Write-Warning "Status Code: $($_.Exception.Response.StatusCode.Value__)"
                Write-Warning "Error Message: $($_.Exception.Message)"
                break
            }

            ## VERBOSE: SUCCESSFUL SUBINTERFACE REMOVAL
            Write-Verbose "Successfully Removed SubInterface ($($SubInterfaceID) !!!"
        }

        if($PSBoundParameters.ContainsKey('SubInterfaces') -eq $true){
            ## LOOP THROUGH ALL SUBINTERFACES
            ForEach ($SUB in $SubInterfaces){

                ## CREATE URL TO REMOVE SINGLE SUBINTERFACE
                $URL = "https://172.16.9.59/api/fmc_config/v1/domain/$($DomainUUID)/devices/devicerecords/$($DeviceUUID)/subinterfaces/$($SUB.id)"
            
                ## VERBOSE: DELETING SUBINTERFACE
                Write-Verbose "Attempting to Delete SubInterface ($($SUB.id) ..."

                ## ATTEMPT TO REMOVE SUBINTERFACE
                try{
                    $RESPONSE = Invoke-WebRequest -Uri $URL -Method Delete -Headers $HEADERS
                }
                catch{
                    Write-Warning "Unable to connect to FMC API Endpoint ($($URL))."
                    Write-Warning "Status Code: $($_.Exception.Response.StatusCode.Value__)"
                    Write-Warning "Error Message: $($_.Exception.Message)"
                    break
                }

                ## VERBOSE: SUCCESSFUL SUBINTERFACE REMOVAL
                Write-Verbose "Successfully Removed SubInterface ($($SUB.id) !!!"

            }
        }
    }

    END {
        ## RETURN SUCCESS MESSAGE
        return "SubInterface(s) Removed Successfully!"
    }

}

## FUNCTION: CREATE SUB-INTERFACES
function New-SubInterface {
    ## DEFINE PARAMETERS
    [CmdletBinding(DefaultParameterSetName='SubInterfaceID')]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [string]$DomainUUID,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [string]$DeviceUUID,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        $Token,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [int]$MTU,

        [Parameter(Mandatory=$false)]
        [switch]$IncludeSecZone
    )

    BEGIN {
        ## VALIDATE PATH
        if((Test-Path -Path $FilePath) -eq $false){
            Write-Error "Unable to Access Sub-Interface JSON ($($FilePath). This is either due to the file not found or permissions."
            break
        }
        
        ## CONVERT JSON TO PSOBJECT
        try{
            $SUBS = Get-Content $FilePath | ConvertFrom-Json
        }
        catch{
            Write-Warning "Unable to Load Sub-Interface JSON ($($FilePath)). This is due to the file not being a valid JSON file."
            break
        }

        ## VERBOSE: OUTPUT NUMBER OF ELEMENTS TO PROCESS
        Write-Verbose "Total Sub-Interfaces to Process: $(($SUBS | Measure-Object).Count)"
        Write-Host "Total Sub-Interfaces to Process: $(($SUBS | Measure-Object).Count)"

        ## DEFINE HEADERS
        $HEADERS = @{
            'x-auth-access-token' = "$($Token.Access)"
            'x-auth-refresh-token' = "$($Token.Refresh)"
        }

        ## DEFINE URL
        $URL = "https://172.16.9.59/api/fmc_config/v1/domain/$($DomainUUID)/devices/devicerecords/$($DeviceUUID)/subinterfaces"

        ## OBTAIN SECURITY ZONES
        if ($IncludeSecZone){
            $ZONES = Get-SecurityZone -Token $Token -DomainUUID $DomainUUID
        }
    }

    PROCESS {
        ## LOOP THROUGH ALL INTERFACES
        ForEach ($SUB in $SUBS){
            ## VERBOSE: OUTPUT SUB-INTERFACE PROGRESS
            Write-Verbose "------------------------------"
            Write-Verbose "Processing Sub-Interface: $($SUB.ifname)"

            ## VALIDATE JSON PROPERTIES


            ## CREATE JSON OBJECT OF SUB-INTERFACE
            $RAW = @{
                name = $SUB.name
                ifname = $SUB.ifname
                ipv4 = @{
                    static = @{
                        address = $SUB.ipv4.static.address
                        netmask = $SUB.ipv4.static.netmask
                    }
                }
                securityZone = @{
                    id = $SUB.securityZone.id
                }
                type = "SubInterface"
                vlanId = $SUB.vlanId
                subIntfId = $SUB.subIntfId
                managementOnly = $false
                MTU = 1500
            }

            ## CONVERT RAW STRING TO JSON
            $BODY = $RAW | ConvertTo-Json

            ## UPDATE SECURITY ZONE (IF REQUESTED)
            if ($IncludeSecZone){
                $TEMP = $BODY | ConvertFrom-Json

                ## SEARCH FOR SECURITY ZONE
                $MYZONE = $ZONES | Where-Object -FilterScript { $_.name -eq $SUB.ifname } | Select -First 1

                ## VALIDATE SECURITY ZONE
                if($MYZONE -eq $null){
                    Write-Warning "UNABLE TO FIND SECURITY ZONE FOR $($SUB.ifname). SUB-INTERFACE WILL BE CREATED WITHOUT SECURITY ZONE"
                    $TEMP.PSObject.Properties.Remove('securityZone')
                }
                else {
                    $TEMP.securityZone.id = $MYZONE.id
                }

                $BODY = $TEMP | ConvertTo-Json
            }
            else {
                $TEMP = $BODY | ConvertFrom-Json
                $TEMP.PSObject.Properties.Remove('securityZone')
                $BODY = $TEMP | ConvertTo-Json
            }

            ## ATTEMPT TO CREATE SUB-INTERFACE
            try{
                $RESPONSE = Invoke-WebRequest -Uri $URL -Method Post -Headers $HEADERS -Body $BODY -ContentType 'application/json'
            }
            catch{
                Write-Warning "Unable to connect to FMC API Endpoint ($($URL))."
                Write-Warning "Status Code: $($_.Exception.Response.StatusCode.Value__)"
                Write-Warning "Error Message: $($_.Exception.Message)"
                break
            }

            ## VERBOSE: CLOSE SUB-INTERFACE SECTION
            Write-Verbose "------------------------------"
        }    
    }

    END {
        ## RETURN SUCESS MESSAGE
        return "Succesfully Created Sub-Interface(s)"
    }

}

## ----- SECURITY ZONES -----

## FUNCTION: GET ALL SECURITY ZONES
function Get-SecurityZone {
    
    ## DEFINE PARAMETERS
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [string]$DomainUUID,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        $Token
    )

    BEGIN {
        ## DEFINE HEADERS
        $HEADERS = @{'x-auth-access-token' = $Token.Access; 'x-auth-refresh-token' = $Token.Refresh}

        ## DEFINE URL
        $URL = "https://172.16.9.59/api/fmc_config/v1/domain/$($DomainUUID)/object/securityzones?expanded=true&limit=250"

        ## DEFINE NEW RESULTS OBJECT
        $RESULTS = @()

        ## DEFINE NEXT FLAG
        [bool]$NEXT = $true
    }
    
    PROCESS {
        ## ATTEMPT TO QUERY FMC API FOR SUB INTERFACES
        try{
            ## LOOP THROUGH ALL RECORDS
            while($NEXT -eq $true){
                ## QUERY API
                $RESPONSE = Invoke-WebRequest -Uri $URL -Method Get -Headers $HEADERS

                ## CONVERT TO PSOBJECT
                $CONTENT = $RESPONSE.Content | ConvertFrom-Json

                ## ADD RECORDS TO ARRAY
                $RESULTS += $CONTENT.items

                ## CHECK FOR NEXT LINK
                if ([bool]($CONTENT.paging.PSObject.Properties.name -match 'next') -eq $false){
                    ## CANCEL LOOP
                    $NEXT = $false
                } else {
                    ## UPDATE URL
                    $URL = $CONTENT.paging.next[0]
                }

            }
        }
        catch{
            Write-Warning "Unable to connect to FMC API Endpoint ($($URL))."
            Write-Warning "Status Code: $($_.Exception.Response.StatusCode.Value__)"
            Write-Warning "Error Message: $($_.Exception.Message)"
            break
        } 
    }

    END {
        ## RETURN RESULTS
        return $RESULTS | select * -ExcludeProperty links, metadata
    }
}


## EXPORT MODULE FUNCTIONS
Export-ModuleMember Connect-FMC, Refresh-Token, Get-Domains, Get-Devices, Get-SubInterfaces, Count-SubInterfaces, Remove-SubInterface, New-SubInterface, Get-SecurityZone
