#URL of the server including the query
#Read how to structure the query here: https://developer.carbonblack.com/reference/enterprise-protection/8.0/rest-api/#query-condition
#In this example the query reads "Return all computers where the NAME property is LIKE (:) the exact value "Workgroup\Win-asdf123"

#Clear Comp Var, mostly for testing
$comp = $null 
$result = $null
$newTag= ""
$updateCount = 0


#Your API Key goes here
$APIKey = '' 

#Your Server URL
$ServerUrl = "https://cb01.res.local"

#Your Query
#$Query = "name:WORKGROUP\\WIN-asdf123".
$Query = "computerTag:"

#What do you want to add to the Tag
$Tag = "Test"

#Use TLS1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Create a Header object
$Header = @{}
$Header.Add("Content-Type",'application/json')
$Header.Add("X-Auth-Token",$APIKey)

#Check the number of objects matching the query
$url = $ServerUrl + "/api/bit9platform/v1/computer?q="+$Query+"&limit=-1"
$Result = Invoke-RestMethod -Header $Header -Uri $Url -Method GET
$Count = $Result.count


$Count.ToString() + " Computers matched the query, possibly including deleted."


#Loop through the computers, 1000 at a time, moving the Offset up each loop
#This loop may work with up to 10000, unable to test in lab

For ($num = 1; $num -le [int][math]::Ceiling($Count/1000); $num++){


    $Offset = ($num -1) * 1000
    
    $url = $ServerUrl + "/api/bit9platform/v1/computer?q="+$Query+"&offset=" + $Offset + "&limit=1000"
    #$url
    #Query and Store Response
    $Response = Invoke-RestMethod -Header $Header -Uri $Url -Method GET


    #Loop through response
    Foreach ($comp in $Response){
        
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


        #Go
        $Result = Invoke-RestMethod -Uri $url -Headers $Header -Method POST -Body $bodyJson
        $updateCount++

        $Updatecount.tostring() + " Computer: " + $Result.name + " was updated with computerTag: " + $Result.computerTag
    }
}




