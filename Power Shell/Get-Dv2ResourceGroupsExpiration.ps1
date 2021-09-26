$managementURL = "https://management.azure.com"
$tenantId = ""
$subId = ""

function Get-AzCachedAccessToken() {
    $currentAzureContext = Get-AzContext
    $azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile;
    $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azureRmProfile);
    $token = $profileClient.AcquireAccessToken($currentAzureContext.Subscription.TenantId).AccessToken;
    return $token
}


function Get-ResourcesCollection {
    param (
        [Parameter (Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $authHeader,
        [Parameter (Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Uri
    )

    $collection = @() 
    while($true) {
        $request = Invoke-RestMethod -Method GET -ContentType "application/json" -Headers $authHeader -Uri $Uri
        if ($request.value) {
            $collection += $request.value
        } else {
            $collection += $request
        }
    
        if($request.nextLink){
            $Uri = $request.nextLink
        }
        else {
            break
        }
    }

    return $collection
}

if ([string]::IsNullOrEmpty($(Get-AzContext).Account)) {
    try {
        Login-AzAccount -TenantId $tenantId -ErrorAction Stop
    } catch {
        Throw "Unable to login to Azure: $($_.Exception.Message)"
    }

}

$authHeader = @{
   "Content-Type" = "application/json"
   "Accept" = "application/json"
   "Authorization" = "Bearer " + (Get-AzCachedAccessToken)
}

$report = @()
$resourceGroups = Get-ResourcesCollection -authHeader $authHeader -Uri "$managementURL/subscriptions/$subId/resourceGroups?api-version=6.0-preview.1&$top=100"

foreach ($rg in $resourceGroups) {
    $rgInfo = Get-ResourcesCollection -authHeader $authHeader -Uri "$($managementURL)$($rg.id)?api-version=6.0-preview.1&$top=100"
    if ($rgInfo.tags.expire) {
        $expiration = ([datetime]$rgInfo.tags.expire).ToUniversalTime()
    } else {
        $expiration = 'None'
    }

    $report += [pscustomobject] @{
        ResourceGroup = $rg.name
        Expiration = $expiration
    }
}

$report | Sort-Object Expiration
