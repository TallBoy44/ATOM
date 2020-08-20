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

## FUNCTION: LOGIN TO FMC
function Login-FMC {
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
            [string]$Token
            [string]$Refresh
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
        $TOKEN.Token = $RESPONSE.Headers.'X-auth-access-token'
        $TOKEN.Refresh = $RESPONSE.Headers.'X-auth-refresh-token'
        
        return $TOKEN
    }

}

## FUNCTION: GET FMC DOMAINS
function Get-Domains {
    ## DEFINE PARAMETERS
    param(
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string]$URL = "https://172.16.9.59/api/fmc_platform/v1/info/domain",

        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [string]$Token
    )

    BEGIN {
        ## DEFINE HEADERS
        $HEADERS = @{'x-auth-access-token' = "$($Token)"}
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
        [string]$Token
    )

    BEGIN {
        ## DEFINE HEADERS
        $HEADERS = @{'x-auth-access-token' = "$($Token)"}

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
        [string]$Token
    )

    BEGIN {
        ## DEFINE HEADERS
        $HEADERS = @{'x-auth-access-token' = "$($Token)"}

        ## DEFINE URL
        $URL = "https://172.16.9.59/api/fmc_config/v1/domain/$($DomainUUID)/devices/devicerecords/$($DeviceUUID)/subinterfaces?expanded=true"
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
        return $RESULTS.items | select * -ExcludeProperty links, metadata
    }

}

## FUNCTION: DELETE SUB-INTERFACES
function Remove-SubInterface{
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
        [string]$SubInterfaceID,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [string]$Token
    )

}