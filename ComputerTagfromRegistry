#Clear Comp Var, mostly for testing
$comp = $null 
$result = $null
$newTag= ""
$updateCount = 0
$url = ""

#Your API Key goes here
$APIKey = '' 

#Your Server URL
$ServerUrl = "https://cb01.res.local"

#Your Query
# Get Domain (NetBIOS)
$domain = ([System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()).GetDirectoryEntry().Name
Write-Host "Domain (NetBIOS): $domain"

# Get Hostname
$hostname = $env:COMPUTERNAME
Write-Host "Hostname: $hostname"
$Query = "name:"+$domain+"\\"+$hostname
#$Query = "computerTag:"

#What do you want to add to the Tag
$registryPath = "HKLM:\System\CurrentControlSet"
$registryEntryName = "FISMATag"
$fullRegistryPath = Join-Path $registryPath $registryEntryName

$registryValue = Get-ItemProperty -Path $registryPath -Name $registryEntryName | Select-Object -ExpandProperty $registryEntryName

Write-Host "Registry Value: $registryValue"

$Tag = $registryValue

#Use TLS1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Create a Header object
$Header = @{}
$Header.Add("Content-Type",'application/json')
$Header.Add("X-Auth-Token",$APIKey)

#Check the number of objects matching the query
$url = $ServerUrl + "/api/bit9platform/v1/computer?q="+$Query+"&limit=-1"
Write-Host $url
$Result = Invoke-RestMethod -Header $Header -Uri $url -Method GET

$Result.count.ToString() + " Computers matched the query, possibly including deleted."

$url = $ServerUrl + "/api/bit9platform/v1/computer?q="+$Query
Write-Host $url
$Result = Invoke-RestMethod -Header $Header -Uri $url -Method GET

#Loop through response
Foreach ($comp in $Result){
        
    #Test if the Tag is null, format accordingly
    if ([string]::IsNullOrEmpty($comp.computerTag)){
        $newTag = $Tag
        }Else
        {
            $newTag = $comp.computerTag + ", " + $Tag
        }
   
    #Create a Body Object including the target computer ID and our new tag
    $Body = @{}
    $Body.add("id",$comp.id)

    $Body.add("computerTag", $newTag)

    #Convert the body to JSON
    $bodyJson = ConvertTo-Json $Body

    #Talk to this API resource
    $url = $ServerUrl + "/api/bit9platform/v1/computer/"
    Write-Host $url

    #Go
    $Result = Invoke-RestMethod -Uri $url -Headers $Header -Method POST -Body $bodyJson
    $updateCount++

    $Updatecount.tostring() + " Computer: " + $Result.name + " was updated with computerTag: " + $Result.computerTag
}
