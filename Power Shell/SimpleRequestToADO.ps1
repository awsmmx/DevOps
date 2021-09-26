$PAT = "PAT"

function Send-RequestToVSTS {
    Param
    (
        [string]$uri
    )
    $cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes((":$PAT")))

    try
    {
        $request = Invoke-RestMethod -ContentType "application/json" -Uri $uri -Headers @{Authorization = "Basic $cred"} -Method Get
        return $request
    }

    catch
    {
        Throw "Unable to get data from '$uri': $($_.Exception.Message)"
    }
}