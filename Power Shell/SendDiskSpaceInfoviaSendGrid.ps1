$server = $env:COMPUTERNAME
    function Send-Email {
        param (
            [string]$bodyContent
        )
        $ncvrtAPIKEY = "API key"
        $decode = [System.Convert]::FromBase64String($ncvrtAPIKEY)
        $SENDGRID_API_KEY = [System.Text.Encoding]::Unicode.GetString($decode)
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headers.Add("Authorization", "Bearer " + $SENDGRID_API_KEY)
        $headers.Add("Content-Type", "application/json")
        $EmailTo = "Email to"
        $EmailFrom = "Email from"
        $Subject = "Subject"
    
        $body = @{
        personalizations = @(
            @{
                to = @(
                        @{
                            email = $EmailTo
                        }
                )
            }
        )
        from = @{
            email = $EmailFrom
        }
        subject = $Subject
        content = @(
            @{
                type = "text/html"
                value = $bodyContent
            }
        )
        }
    
        $bodyJson = $body | ConvertTo-Json -Depth 4
    
        $response = Invoke-RestMethod -Uri https://api.sendgrid.com/v3/mail/send -Method Post -Headers $headers -Body $bodyJson 
        $response

        Write-Output "Done"
        timeout.exe /t 3
    }

$fmtDrive =@{label= "Drive"      ; alignment="left"  ;width=10; Expression={$_.DeviceID};};
$fmtName  =@{label= "Volume Name"; alignment="left"  ;width=10; Expression={$_.VolumeName};};
$fmtSize  =@{label= "Size MB"    ; alignment="right" ;width=10; Expression={$_.Size / 1048576};; FormatString="N0";};
$fmtFree  =@{label= "Free MB"    ; alignment="right" ;width=10; Expression={$_.FreeSpace / 1048576}    ; FormatString="N0";};
$fmtPerc  =@{label= "Free %"     ; alignment="right" ;width=10; Expression={100.0 * $_.FreeSpace / $_.Size}; FormatString="N1";};

$disks = Get-WmiObject -ComputerName $server -Class Win32_LogicalDisk -Filter "DriveType = 3";
   
Write-Output ("Machine name: {0}`tDrives count #: {1}" -f $server, $disks.Count);
Write-Output $disks | Format-Table $fmtDrive, $fmtName, $fmtSize, $fmtFree, $fmtPerc;

$exportList = @()
$nic_configuration = Get-WmiObject -computer . -class "win32_networkadapterconfiguration" | Where-Object {$_.defaultIPGateway -ne $null}

foreach ($disk in $disks) {

    $PercentFreeSpace = [math]::Round((100* $disk.FreeSpace / $disk.Size))
    $MAC_Address = $nic_configuration.MACAddress
    $server_name = $dictionary[$MAC_Address]

    if ($server_name -eq "" -or $null -eq $server_name){
        $server_name = $server
    }

    if ($PercentFreeSpace -lt 15) {
        $exportList += [PSCustomObject] @{
            ` Name         = $server_name
            ` Drive        = $disk.DeviceID; 
            ` VolumeName   = $disk.VolumeName; 
            ` Size         = [math]::Round(($disk.Size / (1048576 * 1000)),0); 
            ` FreeSpace    = [math]::Round(($disk.FreeSpace / (1048576 * 1000))); 
            ` PercentFree  = "$PercentFreeSpace %"};
    }
}

$style = "
<style>
    TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
    TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
    TD{border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
</style>
"
$header = "[INFO]<html><body> <div><br> </br>Disk space lt 15%<br> </br>"

if ($exportList.Length -ne 0) {
    $listOfSpaceHTML = $exportList | ConvertTo-HTML -AS Table -Fragment -PreContent $style | Out-String
    $HTML = ConvertTo-HTML -head $header -Body $listOfSpaceHTML

    Send-Email -bodyContent $HTML
}

