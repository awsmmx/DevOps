function Send-RequestToVSTS {
    param (
        [Parameter(Mandatory = $true)] [string] $uri,
        [Parameter(Mandatory = $true)] $headers
    )
    try {
        $request = Invoke-RestMethod -Uri $uri -Method Get -ContentType "application/json"  -Headers $headers
        return $request
    } catch {
        Throw "Unable to get data from server '$uri': $($_.Exception.Message)"
    }
}

function New-VstsApiUri {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string] $Organization,
        [Parameter()] [string] $Project,
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string] $Api,
        [Parameter()] [hashtable] $Query,
        [Parameter()] [switch] $AccountApi
    )

    $hots = "dev.azure.com"

    $path = "/{0}/{1}/{2}" -f $Organization, $Project, $Api
    if ($AccountApi) { $path = $Api } # Some APIs apply to an entire account
    $querystring = ""
    if ($Query -ne $null -and $Query.Keys.Count -gt 0) {
        $first = $true
        foreach ($key in $Query.Keys) {
            if (!$first) { $querystring += "&" }
            $querystring += "{0}={1}" -f $key, $Query[$key]
            $first = $false
        }
    }

    [UriBuilder] $uri = New-Object -TypeName System.UriBuilder -ArgumentList "https", $hots, -1, $path
    $uri.Query = $queryString
    $uri.ToString()
}

[SecureString] $VstsPassword = $null
function Set-VstsLogin {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [SecureString] $PersonalAccessToken
    )

    $script:VstsPassword = $PersonalAccessToken
}

function Get-VstsAuthToken {
    if ($null -eq $script:VstsPassword) {
        throw "Call Set-VstsLoginFromKeyVault before attempting to use the VSTS API"
    }

    $notsosecret = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($script:VstsPassword)
    $nowitsastring = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($notsosecret)
    [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "ApiUsers", $nowitsastring)))
}

#################
# VSTS Rest Api #
#################

#region Build
function Get-ListOfBuild {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure DevOps organization")] [string] $Organization,
        [Parameter(Mandatory = $true, HelpMessage = "Project ID or project name")] [string] $Project,
        [Parameter(HelpMessage = "If specified, filters to builds that built from this repository")] [string] $RepositoryID,
        [Parameter(HelpMessage = "A comma-delimited list that specifies the IDs of builds to retrieve")] [string[]] $BuildIDs,
        [Parameter(HelpMessage = "If specified, filters to builds that built branches that built this branch")] [string] $BranchName,
        [Parameter(HelpMessage = "The order in which builds should be returned")] [ValidateSet("finishTimeAscending", "finishTimeDescending", "queueTimeAscending", "queueTimeDescending", "startTimeAscending", "startTimeDescending")][string] $QueryOrder,
        [Parameter(HelpMessage = "Indicates whether to exclude, include, or only return deleted builds")] [ValidateSet("excludeDeleted", "includeDeleted", "onlyDeleted")][string] $DeletedFilter,
        [Parameter(HelpMessage = "The maximum number of builds to return per definition")] [string] $MaxBuildsPerDefenition,
        [Parameter(HelpMessage = "A continuation token, returned by a previous call to this method, that can be used to return the next set of builds")] [string] $ContinuationToken,
        [Parameter(HelpMessage = "The maximum number of builds to return")] [string] $Top,
        [Parameter(HelpMessage = "A comma-delimited list of properties to retrieve")] [string[]] $Properties,
        [Parameter(HelpMessage = "A comma-delimited list of tags. If specified, filters to builds that have the specified tags")] [string[]] $TagFilters,
        [Parameter(HelpMessage = "If specified, filters to builds that match this result")] [ValidateSet("canceled", "failed", "none", "partiallySucceeded", "succeeded")] [string] $ResultFilter,
        [Parameter(HelpMessage = "If specified, filters to builds that match this status")] [ValidateSet("all", "cancelling", "completed", "inProgress", "none", "notStarted", "postponed")] [string] $StatusFilter,
        [Parameter(HelpMessage = "If specified, filters to builds that match this reason")] [ValidateSet("all", "batchedCI", "buildCompletion", "checkInShelveset", "individualCI", "manual", "none", "pullRequest", "schedule", "triggered", "userCreated", "validateShelveset")] [string] $ReasonFilter,
        [Parameter(HelpMessage = "If specified, filters to builds requested for the specified user")] [string] $RequestedFor,
        [Parameter(HelpMessage = "If specified, filters to builds that finished/started/queued before this date based on the queryOrder specified")] [datetime] $MaxTime,
        [Parameter(HelpMessage = "If specified, filters to builds that finished/started/queued after this date based on the queryOrder specified")] [datetime] $MinTime,
        [Parameter(HelpMessage = "If specified, filters to builds that match this build number. Append * to do a prefix search")] [string] $BuildNumber,
        [Parameter(HelpMessage = "A comma-delimited list of queue IDs. If specified, filters to builds that ran against these queues")] [string[]] $Queues,
        [Parameter(HelpMessage = "A comma-delimited list of definition IDs. If specified, filters to builds for these definitions")] [string[]] $Definitions,
        [Parameter(HelpMessage = "If specified, filters to builds that built from repositories of this type")] [string] $RepositoryType
    )

    $query = @{"api-version" = "6.0" }
    if (![string]::IsNullOrWhiteSpace($RepositoryID)) { $query["repositoryID"] = $RepositoryID }
    if ($null -ne $BuildIDs -and $BuildIDs.Length -gt 0) { $query["buildIDs"] = [string]::Join(",", $BuildIDs) }
    if (![string]::IsNullOrWhiteSpace($BranchName)) { $query["branchName"] = $BranchName }
    if (![string]::IsNullOrWhiteSpace($QueryOrder)) { $query["queryOrder"] = $QueryOrder }
    if (![string]::IsNullOrWhiteSpace($DeletedFilter)) { $query["deletedFilter"] = $DeletedFilter }
    if (![string]::IsNullOrWhiteSpace($MaxBuildsPerDefenition)) { $query["maxBuildsPerDefenition"] = $MaxBuildsPerDefenition }
    if (![string]::IsNullOrWhiteSpace($ContinuationToken)) { $query["continuationToken"] = $ContinuationToken }
    if (![string]::IsNullOrWhiteSpace($Top)) { $query["top"] = $Top }
    if ($null -ne $Properties -and $Properties.Length -gt 0) { $query["properties"] = [string]::Join(",", $Properties) }
    if ($null -ne $TagFilters -and $TagFilters.Length -gt 0) { $query["tagFilters"] = [string]::Join(",", $TagFilters) }
    if (![string]::IsNullOrWhiteSpace($ResultFilter)) { $query["resultFilter"] = $ResultFilter }
    if (![string]::IsNullOrWhiteSpace($StatusFilter)) { $query["statusFilter"] = $StatusFilter }
    if (![string]::IsNullOrWhiteSpace($ReasonFilter)) { $query["reasonFilter"] = $ReasonFilter }
    if (![string]::IsNullOrWhiteSpace($RequestedFor)) { $query["requestedFor"] = $RequestedFor }
    if ($MaxTime -ne $null) { $query["maxTime"] = $MaxTime.ToString() }
    if ($MinTime -ne $null) { $query["minTime"] = $MinTime.ToString() }
    if (![string]::IsNullOrWhiteSpace($BuildNumber)) { $query["buildNumber"] = $BuildNumber }
    if ($null -ne $Queues -and $Queues.Length -gt 0) { $query["queues"] = [string]::Join(",", $Queues) }
    if ($null -ne $Definitions -and $Definitions.Length -gt 0) { $query["definitions"] = [string]::Join(",", $Definitions) }
    if (![string]::IsNullOrWhiteSpace($RepositoryType)) { $query["repositoryType"] = $RepositoryType }

    $uri = New-VstsApiUri -Organization $Organization -Project $Project -Api "_apis/build/builds" -Query $query
    $headers = @{
        Authorization = "Basic {0}" -f (Get-VstsAuthToken)
    }

    Write-Verbose ("Querying builds with Uri {0}" -f $uri)
    Send-RequestToVSTS -uri $uri -headers $headers
}

function Get-Build {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure DevOps organization")] [string] $Organization,
        [Parameter(Mandatory = $true, HelpMessage = "Project ID or project name")] [string] $Project,
        [Parameter(Mandatory = $true, HelpMessage = "The ID of the build")] [string] $BuildID
    )

    $query = @{"api-version" = "6.0" }
    $uri = New-VstsApiUri -Organization $Organization -Project $Project -Api "_apis/build/builds/$BuildID" -Query $query
    $headers = @{
        Authorization = "Basic {0}" -f (Get-VstsAuthToken)
    }

    Write-Verbose ("Querying builds with Uri {0}" -f $uri)
    Send-RequestToVSTS -uri $uri -headers $headers
}

function Get-BuildArtifacts {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure DevOps organization")] [string] $Organization,
        [Parameter(Mandatory = $true, HelpMessage = "Project ID or project name")] [string] $Project,
        [Parameter(Mandatory = $true, HelpMessage = "The ID of the build")] [string] $BuildID
    )
    $query = @{"api-version" = "6.0" }
    $uri = New-VstsApiUri -Organization $Organization -Project $Project -Api "_apis/build/builds/$BuildID/artifacts" -Query $query
    $headers = @{
        Authorization = "Basic {0}" -f (Get-VstsAuthToken)
    }

    Write-Verbose ("Querying artifacts with Uri {0}" -f $uri)
    Send-RequestToVSTS -uri $uri -headers $headers
}

function Get-BuildChanges {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure DevOps organization")] [string] $Organization,
        [Parameter(Mandatory = $true, HelpMessage = "Project ID or project name")] [string] $Project,
        [Parameter(Mandatory = $true, HelpMessage = "The ID of the build")] [string] $BuildID
    )
    $query = @{"api-version" = "6.0" }
    $uri = New-VstsApiUri -Organization $Organization -Project $Project -Api "_apis/build/builds/$BuildID/changes" -Query $query
    $headers = @{
        Authorization = "Basic {0}" -f (Get-VstsAuthToken)
    }

    Write-Verbose ("Querying artifacts with Uri {0}" -f $uri)
    Send-RequestToVSTS -uri $uri -headers $headers
}

function Get-BuildLogs {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure DevOps organization")] [string] $Organization,
        [Parameter(Mandatory = $true, HelpMessage = "Project ID or project name")] [string] $Project,
        [Parameter(Mandatory = $true, HelpMessage = "The ID of the build")] [string] $BuildID
    )
    $query = @{"api-version" = "6.0" }
    $uri = New-VstsApiUri -Organization $Organization -Project $Project -Api "_apis/build/builds/$BuildID/logs" -Query $query
    $headers = @{
        Authorization = "Basic {0}" -f (Get-VstsAuthToken)
    }

    Write-Verbose ("Querying artifacts with Uri {0}" -f $uri)
    Send-RequestToVSTS -uri $uri -headers $headers
}

function Get-BuildLog {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure DevOps organization")] [string] $Organization,
        [Parameter(Mandatory = $true, HelpMessage = "Project ID or project name")] [string] $Project,
        [Parameter(Mandatory = $true, HelpMessage = "The ID of the build")] [string] $BuildID,
        [Parameter(Mandatory = $true, HelpMessage = "The ID of the log file")] [string] $LogID,
        [Parameter(HelpMessage = "The start line")] [string] $StartLine,
        [Parameter(HelpMessage = "The end line")] [string] $EndLine
    )

    $query = @{"api-version" = "6.0" }
    if (![string]::IsNullOrWhiteSpace($StartLine)) { $query["startLine"] = $StartLine }
    if (![string]::IsNullOrWhiteSpace($EndLine)) { $query["endLine"] = $EndLine }

    $uri = New-VstsApiUri -Organization $Organization -Project $Project -Api "_apis/build/builds/$BuildID/logs/$LogID" -Query $query
    $headers = @{
        Authorization = "Basic {0}" -f (Get-VstsAuthToken)
    }

    Write-Verbose ("Querying artifacts with Uri {0}" -f $uri)
    Send-RequestToVSTS -uri $uri -headers $headers
}

function Get-DetailsForBuild {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure DevOps organization")] [string] $Organization,
        [Parameter(Mandatory = $true, HelpMessage = "Project ID or project name")] [string] $Project,
        [Parameter(Mandatory = $true, HelpMessage = "The ID of the build")] [string] $BuildID,
        [Parameter(HelpMessage = "The ID of the timeline")] [string] $TimeLineID,
        [Parameter(HelpMessage = "The ID of the change")] [string] $ChangeID,
        [Parameter(HelpMessage = "")] [string] $PlanID
    )

    $query = @{"api-version" = "6.0" }
    if (![string]::IsNullOrWhiteSpace($TimeLineID)) { $query["timeLineID"] = $TimeLineID }
    if (![string]::IsNullOrWhiteSpace($ChangeID)) { $query["changeID"] = $ChangeID }
    if (![string]::IsNullOrWhiteSpace($PlanID)) { $query["planID"] = $PlanID }

    $uri = New-VstsApiUri -Organization $Organization -Project $Project -Api "_apis/build/builds/$BuildID/timeline/$TimeLineID" -Query $query
    $headers = @{
        Authorization = "Basic {0}" -f (Get-VstsAuthToken)
    }
    Send-RequestToVSTS -uri $uri -headers $headers
}
#endregion

#region Definition
function Get-ListOfDefinition {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure DevOps organization")] [string] $Organization,
        [Parameter(Mandatory = $true, HelpMessage = "Project ID or project name")] [string] $Project,
        [Parameter(HelpMessage = "If specified, filters to definitions with the given process type")] [string] $ProcessType,
        [Parameter(HelpMessage = "If specified, filters to definitions that use the specified task")] [string] $TaskIdFilter,
        [Parameter(HelpMessage = "Indicates whether to return the latest and latest completed builds for this definition")] [string] [ValidateSet("true", "false")] $IncludeLatestBuilds,
        [Parameter(HelpMessage = "Indicates whether the full definitions should be returned. By default, shallow representations of the definitions are returned")] [string] [ValidateSet("true", "false")] $IncludeAllProperties,
        [Parameter(HelpMessage = "If specified, filters to definitions that do not have builds after this date")] [datetime] $NotBuiltAfter,
        [Parameter(HelpMessage = "If specified, filters to definitions that have builds after this date")] [datetime] $BuiltAfter,
        [Parameter(HelpMessage = "If specified, filters to definitions under this folder")] [string] $Path,
        [Parameter(HelpMessage = "A comma-delimited list that specifies the IDs of definitions to retrieve")] [string[]] $DefinitionIds,
        [Parameter(HelpMessage = "If specified, indicates the date from which metrics should be included")] [datetime] $MinMetricsTime,
        [Parameter(HelpMessage = "A continuation token, returned by a previous call to this method, that can be used to return the next set of definitions")] [string] $ContinuationToken,
        [Parameter(HelpMessage = "The maximum number of definitions to return")] [string] $Top,
        [Parameter(HelpMessage = "Indicates the order in which definitions should be returned")] [ValidateSet("definitionNameAscending", "definitionNameDescending", "lastModifiedAscending", "lastModifiedDescending", "none")] [string] $QueryOrder,
        [Parameter(HelpMessage = "If specified, filters to definitions that have a repository of this type")] [string] $RepositoryType,
        [Parameter(HelpMessage = "A repository ID. If specified, filters to definitions that use this repository")] [string] $RepositoryId,
        [Parameter(HelpMessage = "If specified, filters to definitions whose names match this pattern")] [string] $Name,
        [Parameter(HelpMessage = "If specified, filters to YAML definitions that match the given filename")] [string] $YamlFilename
    )

    $query = @{"api-version" = "6.0" }
    if (![string]::IsNullOrWhiteSpace($ProcessType)) { $query["processType"] = $ProcessType }
    if (![string]::IsNullOrWhiteSpace($TaskIdFilter)) { $query["taskIdFilter"] = $TaskIdFilter }
    if (![string]::IsNullOrWhiteSpace($IncludeLatestBuilds)) { $query["includeLatestBuilds"] = $IncludeLatestBuilds }
    if (![string]::IsNullOrWhiteSpace($IncludeAllProperties)) { $query["includeAllProperties"] = $IncludeAllProperties }
    if ($NotBuiltAfter -ne $null) { $query["notBuiltAfter"] = $NotBuiltAfter.ToString() }
    if ($BuiltAfter -ne $null) { $query["builtAfter"] = $BuiltAfter.ToString() }
    if (![string]::IsNullOrWhiteSpace($Path)) { $query["path"] = $Path }
    if ($null -ne $DefinitionIds -and $DefinitionIds.Length -gt 0) { $query["definitionIds"] = [string]::Join(",", $DefinitionIds) }
    if ($MinMetricsTime -ne $null) { $query["minMetricsTime"] = $MinMetricsTime.ToString() }
    if (![string]::IsNullOrWhiteSpace($ContinuationToken)) { $query["continuationToken"] = $ContinuationToken }
    if (![string]::IsNullOrWhiteSpace($Top)) { $query['$top'] = $Top }
    if (![string]::IsNullOrWhiteSpace($QueryOrder)) { $query["queryOrder"] = $QueryOrder }
    if (![string]::IsNullOrWhiteSpace($RepositoryType)) { $query["repositoryType"] = $RepositoryType }
    if (![string]::IsNullOrWhiteSpace($RepositoryId)) { $query["repositoryId"] = $RepositoryId }
    if (![string]::IsNullOrWhiteSpace($Name)) { $query["name"] = $Name }
    if (![string]::IsNullOrWhiteSpace($YamlFilename)) { $query["yamlFilename"] = $YamlFilename }

    $uri = New-VstsApiUri -Organization $Organization -Project $Project -Api "_apis/build/definitions" -Query $query
    $headers = @{
        Authorization = "Basic {0}" -f (Get-VstsAuthToken)
    }
    Send-RequestToVSTS -uri $uri -headers $headers
}

function Get-Definition {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure DevOps organization")] [string] $Organization,
        [Parameter(Mandatory = $true, HelpMessage = "Project ID or project name")] [string] $Project,
        [Parameter(Mandatory = $true, HelpMessage = "The ID of the definition")] [string] $DefinitonID,
        [Parameter(HelpMessage = "The revision number to retrieve. If this is not specified, the latest version will be returned")] [string] $Revision,
        [Parameter(HelpMessage = "If specified, indicates the date from which metrics should be included")] [datetime] $MinMetricsTime,
        [Parameter()] [ValidateSet("true", "false")] [string] $IncludeLatestBuilds
    )

    $query = @{"api-version" = "6.0" }
    if (![string]::IsNullOrWhiteSpace($Revision)) { $query["revision"] = $Revision }
    if ($MinMetricsTime -ne $null) { $query["minMetricsTime"] = $MinMetricsTime.ToString() }
    if (![string]::IsNullOrWhiteSpace($IncludeLatestBuilds)) { $query["includeLatestBuilds"] = $IncludeLatestBuilds }

    $uri = New-VstsApiUri -Organization $Organization -Project $Project -Api "_apis/build/definitions/$DefinitonID" -Query $query
    $headers = @{
        Authorization = "Basic {0}" -f (Get-VstsAuthToken)
    }
    Send-RequestToVSTS -uri $uri -headers $headers
}

function Get-DefinitionRevisions {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure DevOps organization")] [string] $Organization,
        [Parameter(Mandatory = $true, HelpMessage = "Project ID or project name")] [string] $Project,
        [Parameter(Mandatory = $true, HelpMessage = "The ID of the definition")] [string] $DefinitonID
    )

    $query = @{"api-version" = "6.0" }

    $uri = New-VstsApiUri -Organization $Organization -Project $Project -Api "_apis/build/definitions/$DefinitonID/revisions" -Query $query
    $headers = @{
        Authorization = "Basic {0}" -f (Get-VstsAuthToken)
    }
    Send-RequestToVSTS -uri $uri -headers $headers
}

function Get-LatestBuild {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure DevOps organization")] [string] $Organization,
        [Parameter(Mandatory = $true, HelpMessage = "Project ID or project name")] [string] $Project,
        [Parameter(Mandatory = $true, HelpMessage = "Definition name with optional leading folder path, or the definition ID")] [string] $Definition,
        [Parameter(HelpMessage = "Optional parameter that indicates the specific branch to use")] [string] $BranchName
    )

    $query = @{"api-version" = "6.0-preview.1" }
    if (![string]::IsNullOrWhiteSpace($BranchName)) { $query["branchName"] = $BranchName }

    $uri = New-VstsApiUri -Organization $Organization -Project $Project -Api "_apis/build/latest/$Definition" -Query $query
    $headers = @{
        Authorization = "Basic {0}" -f (Get-VstsAuthToken)
    }
    Send-RequestToVSTS -uri $uri -headers $headers
}
#endregion

#region Folder
function Get-ListOfFolders {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure DevOps organization")] [string] $Organization,
        [Parameter(Mandatory = $true, HelpMessage = "Project ID or project name")] [string] $Project,
        [Parameter(HelpMessage = "The path to start with")] [string] $Path,
        [Parameter(HelpMessage = "The order in which folders should be returned")] [ValidateSet("folderAscending", "folderDescending", "none")] [string] $QueryOrder
    )

    $query = @{"api-version" = "6.0-preview.2" }
    if (![string]::IsNullOrWhiteSpace($QueryOrder)) { $query["queryOrder"] = $QueryOrder }

    $uri = New-VstsApiUri -Organization $Organization -Project $Project -Api "_apis/build/folders/$Path" -Query $query
    $headers = @{
        Authorization = "Basic {0}" -f (Get-VstsAuthToken)
    }
    Send-RequestToVSTS -uri $uri -headers $headers
}
#endregion

#region Project
function Get-ListOfProjects {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure DevOps organization")] [string] $Organization,
        [Parameter(HelpMessage = "Filter on team projects in a specific team project state (default: WellFormed)")] [ValidateSet("all", "createPending", "deleted", "deleting", "new", "unchanged", "wellFormed")][string] $StateFilter
    )

    $query = @{"api-version" = "6.0" }
    if (![string]::IsNullOrWhiteSpace($StateFilter)) { $query["stateFilter"] = $StateFilter }

    $uri = New-VstsApiUri -Organization $Organization -Api "_apis/projects" -Query $query
    $headers = @{
        Authorization = "Basic {0}" -f (Get-VstsAuthToken)
    }
    Send-RequestToVSTS -uri $uri -headers $headers
}

function Get-Project {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure DevOps organization")] [string] $Organization,
        [Parameter(Mandatory = $true, HelpMessage = "Project ID")] [string] $ProjectId,
        [Parameter(HelpMessage = "Include capabilities (such as source control) in the team project result (default: false)")] [string] [ValidateSet("true", "false")] $IncludeCapabilities,
        [Parameter(HelpMessage = "Search within renamed projects (that had such name in the past)")] [string] [ValidateSet("true", "false")] $IncludeHistory
    )

    $query = @{"api-version" = "6.0" }
    if (![string]::IsNullOrWhiteSpace($IncludeCapabilities)) { $query["includeCapabilities"] = $IncludeCapabilities }
    if (![string]::IsNullOrWhiteSpace($IncludeHistory)) { $query["includeHistory"] = $IncludeHistory }

    $uri = New-VstsApiUri -Organization $Organization -Api "_apis/projects/$ProjectId" -Query $query
    $headers = @{
        Authorization = "Basic {0}" -f (Get-VstsAuthToken)
    }
    Send-RequestToVSTS -uri $uri -headers $headers
}

function Get-ProjectProperties {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "")] [string] $Organization,
        [Parameter(Mandatory = $true, HelpMessage = "")] [string] $ProjectId,
        [Parameter(HelpMessage = "")] [string] $Keys
    )

    $query = @{"api-version" = "6.0-preview.1" }
    if (![string]::IsNullOrWhiteSpace($Keys)) { $query["keys"] = $Keys }

    $uri = New-VstsApiUri -Organization $Organization -Api "_apis/projects/$ProjectId/properties" -Query $query
    $headers = @{
        Authorization = "Basic {0}" -f (Get-VstsAuthToken)
    }
    Send-RequestToVSTS -uri $uri -headers $headers
}
#endregion

#region Test Runs
function Get-ListOfTestRuns {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure DevOps organization")] [string] $Organization,
        [Parameter(Mandatory = $true, HelpMessage = "Project ID or project name")] [string] $Project,
        [Parameter(HelpMessage = "URI of the build that the runs used")] [string] $BuildUri,
        [Parameter(HelpMessage = "Team foundation ID of the owner of the runs")] [string] $Owner,
        [Parameter(HelpMessage = "")] [string] $TmiRunId,
        [Parameter(HelpMessage = "ID of the test plan that the runs are a part of")] [string] $PlanId,
        [Parameter(HelpMessage = "If true, include all the properties of the runs")] [ValidateSet("true", "false")] [string] $IncludeRunDetails,
        [Parameter(HelpMessage = "If true, only returns automated runs")] [ValidateSet("true", "false")] [string] $Automated,
        [Parameter(HelpMessage = "Number of test runs to skip")] [string] $Skip,
        [Parameter(HelpMessage = "Number of test runs to return")] [string] $Top
    )

    $query = @{"api-version" = "6.0" }
    if (![string]::IsNullOrWhiteSpace($BuildUri)) { $query["buildUri"] = $BuildUri }
    if (![string]::IsNullOrWhiteSpace($Owner)) { $query["owner"] = $Owner }
    if (![string]::IsNullOrWhiteSpace($TmiRunId)) { $query["tmiRunId"] = $TmiRunId }
    if (![string]::IsNullOrWhiteSpace($PlanId)) { $query["planId"] = $PlanId }
    if (![string]::IsNullOrWhiteSpace($IncludeRunDetails)) { $query["includeRunDetails"] = $IncludeRunDetails }
    if (![string]::IsNullOrWhiteSpace($Automated)) { $query["automated"] = $Automated }
    if (![string]::IsNullOrWhiteSpace($Skip)) { $query['$skip'] = $Skip }
    if (![string]::IsNullOrWhiteSpace($Top)) { $query['$top'] = $Top }

    $uri = New-VstsApiUri -Organization $Organization -Project $Project -Api "_apis/test/runs" -Query $query
    $headers = @{
        Authorization = "Basic {0}" -f (Get-VstsAuthToken)
    }
    Send-RequestToVSTS -uri $uri -headers $headers
}

function Get-TestRun {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure DevOps organization")] [string] $Organization,
        [Parameter(Mandatory = $true, HelpMessage = "Project ID or project name")] [string] $Project,
        [Parameter(Mandatory = $true, HelpMessage = "ID of the run to get")] [string] $RunId,
        [Parameter(HelpMessage = "Defualt value is true. It includes details like run statistics,release,build,Test enviornment,Post process state and more")] [ValidateSet("true", "false")] [string] $IncludeDetails
    )

    $query = @{"api-version" = "6.0" }
    if (![string]::IsNullOrWhiteSpace($IncludeDetails)) { $query["includeDetails"] = $IncludeDetails }

    $uri = New-VstsApiUri -Organization $Organization -Project $Project -Api "_apis/test/runs/$RunId" -Query $query
    $headers = @{
        Authorization = "Basic {0}" -f (Get-VstsAuthToken)
    }
    Send-RequestToVSTS -uri $uri -headers $headers
}

function Get-TestResult {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure DevOps organization")] [string] $Organization,
        [Parameter(Mandatory = $true, HelpMessage = "Project ID or project name")] [string] $Project,
        [Parameter(Mandatory = $true, HelpMessage = "Test run ID of a test result to fetch")] [string] $RunId,
        [Parameter(Mandatory = $true, HelpMessage = "Test result ID")] [string] $TestCaseResultId,
        [Parameter(HelpMessage = "Details to include with test results. Default is None. Other values are Iterations, WorkItems and SubResults")] [ValidateSet("iterations", "none", "point", "subResults", "workItems")] [string] $DetailsToInclude
    )

    $query = @{"api-version" = "6.0" }
    if (![string]::IsNullOrWhiteSpace($DetailsToInclude)) { $query["detailsToInclude"] = $DetailsToInclude }

    $uri = New-VstsApiUri -Organization $Organization -Project $Project -Api "_apis/test/Runs/$RunId/results/$TestCaseResultId" -Query $query
    $headers = @{
        Authorization = "Basic {0}" -f (Get-VstsAuthToken)
    }
    Send-RequestToVSTS -uri $uri -headers $headers
}

function Get-ListOfTestResult {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure DevOps organization")] [string] $Organization,
        [Parameter(Mandatory = $true, HelpMessage = "Project ID or project name")] [string] $Project,
        [Parameter(Mandatory = $true, HelpMessage = "Test run ID of test results to fetch")] [string] $RunId,
        [Parameter(HelpMessage = "Details to include with test results. Default is None. Other values are Iterations and WorkItems")] [ValidateSet("iterations", "none", "point", "subResults", "workItems")] [string] $DetailsToInclude,
        [Parameter(HelpMessage = "Number of test results to skip from beginning")] [string] $Skip,
        [Parameter(HelpMessage = "Number of test results to return. Maximum is 1000 when detailsToInclude is None and 200 otherwise")] [string] $Top,
        [Parameter(HelpMessage = "Comma separated list of test outcomes to filter test results")] [string] $Outcomes
    )

    $query = @{"api-version" = "6.0" }
    if (![string]::IsNullOrWhiteSpace($DetailsToInclude)) { $query["detailsToInclude"] = $DetailsToInclude }
    if (![string]::IsNullOrWhiteSpace($Skip)) { $query['$skip'] = $Skip }
    if (![string]::IsNullOrWhiteSpace($Top)) { $query['$top'] = $Top }
    if (![string]::IsNullOrWhiteSpace($Outcomes)) { $query["outcomes"] = $Outcomes }

    $uri = New-VstsApiUri -Organization $Organization -Project $Project -Api "_apis/test/Runs/$RunId/results" -Query $query
    $headers = @{
        Authorization = "Basic {0}" -f (Get-VstsAuthToken)
    }
    Send-RequestToVSTS -uri $uri -headers $headers
}
#endregion