
$Global:GITHUB_USER = ""
$Global:GITHUB_TOKEN = ""
$Global:REPOS_VISIBILITY_TYPE = "public" # which type of repos to convert: public or private

#start running
[GitHub]::reposToPrivate()


class GitHub {

    static [void] reposToPrivate(){

        $jsonStr = ""
        $pageNo = 1
        
        # if REPOS_VISIBILITY_TYPE = "public" then value must be "true", if REPOS_VISIBILITY_TYPE = "private" then value must be "false"
        if ($Global:REPOS_VISIBILITY_TYPE -eq "public") {
            $Global:SET_TO_PRIVATE = "true"
        }
        else {
            $Global:SET_TO_PRIVATE = "false"
        }

        Do {
        
            $jsonStr = [GitHub]::getRepos($pageNo) # get json list of repos as json string
            $json = [GitHub]::convertJson($jsonStr) # convert json string
            [GitHub]::handleJsonForPrivate($json) # loop through repos list and switch private value

            $pageNo++
        
        } Until ($jsonStr -eq "[]") # if has no more page with repos than quits the loop
        

    }
    static [string] getRepos($pageNo){

        $endpoint = "https://api.github.com/user/repos?visibility=$($Global:REPOS_VISIBILITY_TYPE)&page=$($pageNo)"
        $resp = [GitHub]::callApi($endpoint, "GET", $false, @{})
        
        return $resp
    }
    static [void] handleJsonForPrivate($json){

        foreach($obj in $json){

            Write-Host "endpoint: $($obj.url)"
            $endpoint = $obj.url
            $resp = [GitHub]::setRepoToPrivate($endpoint)
            $respJson = [GitHub]::convertJson($resp)
            Write-Host "private = $($respJson.private)"
   
        }

    }
    static [string] setRepoToPrivate($endpoint){

        $postParams = @{"private"="$($Global:SET_TO_PRIVATE)"}
        $resp = [GitHub]::callApi($endpoint, "PATCH", $true, $postParams)

        return $resp
    }
    static [string] b64Authentication(){

        $AuthBytes  = [System.Text.Encoding]::Ascii.GetBytes("$($Global:GITHUB_USER):$Global:GITHUB_TOKEN")
        return [Convert]::ToBase64String($AuthBytes)

    }
    static [string] callApi([string]$endpoint, [string]$methodType, [bool]$hasPostParams, [hashtable]$postParams){

        $resp = ""

        if($hasPostParams){
            $resp = Invoke-WebRequest -Uri $endpoint -Headers @{"Authorization"="Basic $([GitHub]::b64Authentication())"; "Accept"="application/vnd.github.v3+json"} -Method $methodType -Body ($postParams|ConvertTo-Json)
        } else {
            $resp = Invoke-WebRequest -Uri $endpoint -Headers @{"Authorization"="Basic $([GitHub]::b64Authentication())"; "Accept"="application/vnd.github.v3+json"} -Method $methodType
        }

        return $resp
    }
    static [Object] convertJson($jsonStr){
    
        #Write-Host "jsonStr: $($jsonStr)"
        $json = $jsonStr | ConvertFrom-JSON

        return $json
    }

}
