#######################################################################
##Search for Computer(s) by name from file, search for policy by name, Move Computers to policy
##Joe Fonti for CBAC Customers -- Unsupported, No Version Control.
##6/3/2021
#######################################################################

#Create a function to help us log to both disk and the Console.
Function Write-Log{
    param(
                                [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $LogStatement,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int] $LogLevel)

    PROCESS{
        if($LogLevel -le $global:logServerity){
            Write-Host $LogStatement
            if ($global:bLogToDisk){
                try { 
                    $LogStatement | Out-File -FilePath $global:LogPath -Append 
                }catch{
                    Write-Warning -Message "Unable to write LogFile."
                }
        }
        }
        
    }
}

#Clear Vars
$comp = $null 
$result = $null
$PolicyResult = $null
$updateCount = 0
$PolicyId = $null

#######################################################################
#Begin User Vars area
#######################################################################

#Your API Key goes here
$APIKey = 'C2B6702E-1872-4427-9EF1-7C41EAF8CB97' 

#Your Server URL
$ServerUrl = "https://cb01.res.local"
$ServerUrl = $ServerUrl.Trim()

#Your File Source
$Path = "C:\Temp\Computers.csv"

#Your Destination Policy
$PolicyName = "Policy Name With Spaces "
$PolicyName = $PolicyName.trim()

##### Logging Vars#########
[bool]$global:bLogToDisk = $true
#Integer value 0 Error, 1 Information, 2 Verbose
[int]$global:logServerity = 1

#Logging File Name, Given as a date time stamp
$logFileName = (Get-Date -Format MM-dd-yyyy-hh-mm-ss).tostring() + ".log"

#Your logging path here
$global:LogPath = "C:\Temp\" + $logFileName
#######################################################################
#End User Vars area
#######################################################################

#Write a File Header
$LogStatement = "Attempting to move computers from: " + $Path + " to Policy: " + $PolicyName
Write-Log -LogStatement $LogStatement -LogLevel 0

#Use TLS1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Create a Header object
$Header = @{}
$Header.Add("Content-Type",'application/json')
$Header.Add("X-Auth-Token",$APIKey)

#An Error here may indicate that the file contains duplicates.
Try{
    $csvContent = Import-Csv -Path $Path
}Catch{
    Write-Log -LogStatement "The following error may indicate that the given CSV file could not be read, or may contain duplicates." -LogLevel 0
    Write-Log -LogStatement $_ -LogLevel 0
    Exit
}


#This script relies on structuring queries to the CB API
#Read how to structure the query here: https://developer.carbonblack.com/reference/enterprise-protection/8.0/rest-api/#query-condition
$url = $ServerUrl + "/api/bit9platform/v1/policy?q=name:"+$PolicyName
Write-Log -LogStatement "URL is: $url" -LogLevel 2

Try{
    $Result = Invoke-RestMethod -Header $Header -Uri $Url -Method GET
}Catch{
    Write-Log -LogStatement $_ -LogLevel 0
    Exit
}

$PolicyId = $Result.id

if ([string]::IsNullOrEmpty($PolicyId)){
    $LogStatement = "Something went wrong with Looking up the policy ID for: " + $PolicyName + "`n Check that the Policy Name Matches Exactly in the CB Console."
    Write-Log -LogStatement $LogStatement -LogLevel 0
    Exit
}


foreach ($line in $csvContent)
{
    #Manually clear critical vars to ensure that the loop is clean.
    $SearchName = $null
    $Query = $null
    $url = $null
    $Result = $null
    $PolicyResult = $null
    $body = $null

    Write-Log -LogStatement "Now checking: $line" -LogLevel 2
    #Test if the Computer Name includes a \, if it does, format escape character.
    if ($line.'Workstation Name'.Contains("\")){
        $SearchName = $line.'Workstation Name'.Replace("\","\\")
    }Else{
        $SearchName = $line.'Workstation Name'
    }

    Write-Log -LogStatement "Search Name is: $SearchName" -LogLevel 2
    
    #Build a Query and check if the computer exist by name and is NOT deleted.
    $Query = "name:*" + $SearchName + "&q=deleted:FALSE&limit=-1"
    $url = $ServerUrl + "/api/bit9platform/v1/computer?q="+$Query 
    Write-Log -LogStatement "URL is: $url" -LogLevel 2
    
    Try{
        $Result = Invoke-RestMethod -Header $Header -Uri $Url -Method GET
    }Catch{
        Write-Log -LogStatement $_ -LogLevel 0
        Continue
    }
       
    $LogStatement = "Result Count is: " + $result.count
    Write-Log -LogStatement $LogStatement -LogLevel 2

    #If the previous query is zero, a computer was not found. Continue statement goes to next computer.
    if ($Result.count -eq 0){
        $LogStatement = "Computer Not Found: " + $SearchName
        Write-Log -LogStatement $LogStatement -LogLevel 1
        Continue
        
        }Else{
        
        #Build a Query and check if the computer matches the given destination policy
        $Query = "name:*" + $SearchName + "&q=deleted:FALSE&q=policyName!"+$PolicyName+"&limit=-1"
        $url = $ServerUrl + "/api/bit9platform/v1/computer?q="+$Query
        Write-Log -LogStatement "URL is: $url" -LogLevel 2
        
        Try{
            $PolicyResult = Invoke-RestMethod -Header $Header -Uri $Url -Method GET
        }Catch{
            Write-Log -LogStatement $_ -LogLevel 0
            Continue
        }
                
        $LogStatement = "Result Count is: " + $PolicyResult.count
        Write-Log -LogStatement $LogStatement -LogLevel 2
        }
    
    #If the previous query is zero, a computer object is already in the given policy. Continue goes to next computer.
    if($PolicyResult.count -eq 0){ 
        $LogStatement = "Computer already in destination policy: " + $line.'Workstation Name'
        Write-Log -LogStatement $LogStatement -LogLevel 1
        Continue
    }Else{
        #If we made it to here, we have a computer which needs to be moved.
        $LogStatement = "Computer found, and not in Policy, Attemptin to move."
        Write-Log -LogStatement $LogStatement -LogLevel 1
        
        
        #Get the computer Object
        $Query = "name:*" + $SearchName
        $url = $ServerUrl + "/api/bit9platform/v1/computer?q="+$Query
        $Result = Invoke-RestMethod -Header $Header -Uri $Url -Method GET
        
        ###Begin prep for POST ing the update to the computer.
        #Create a Body Object including the target computer ID and our new tag
        $Body = @{}
        $Body.add("id",$Result.id)
        $Body.add("policyId", $Policyid)

        #If the Body ID field is empty, something went wrong in the previous lookup, abort and go to next computer.
        if ([string]::IsNullOrEmpty($body.id)){
            $LogStatement = "Something went wrong with Looking up the Computer ID for: " + $SearchName
            Write-Log -LogStatement $LogStatement -LogLevel 0
            Continue
        }

        $LogStatement = "Computer id in Body is: " + $body.id
        Write-Log -LogStatement $LogStatement -LogLevel 2

        $LogStatement = "Destination Policy id in Body is: " + $body.policyId
        Write-Log -LogStatement $LogStatement -LogLevel 2

        #Convert the body to JSON
        $bodyJson = ConvertTo-Json $Body

        #Talk to this API resource
        $url = $ServerUrl + "/api/bit9platform/v1/computer/"
        Write-Log -LogStatement "URL is: $url" -LogLevel 2

        #Try to update the computer object with the body (ID/PolicyID) given above
        Try{
            $Result = Invoke-RestMethod -Uri $url -Headers $Header -Method POST -Body $bodyJson
        }catch [System.Net.WebException]{
            Write-Log -LogStatement $_ -LogLevel 0
            Continue
        }
            
        #Test if the Update was successful
        if ($result.policyId -eq $PolicyId){
            $updateCount++
            $LogStatement = $Updatecount.tostring() + " Computer: " + $Result.name + " was updated with policyName: " + $Result.policyName
            Write-Log -LogStatement $LogStatement -LogLevel 1
        }       

    }
}



