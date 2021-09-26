
$server = $env:COMPUTERNAME
$fmtDrive =@{label= "Drive"      ; alignment="left"  ;width=10; Expression={$_.DeviceID};};
$fmtName  =@{label= "Volume Name"; alignment="left"  ;width=10; Expression={$_.VolumeName};};
$fmtSize  =@{label= "Size MB"    ; alignment="right" ;width=10; Expression={$_.Size / 1048576};; FormatString="N0";};
$fmtFree  =@{label= "Free MB"    ; alignment="right" ;width=10; Expression={$_.FreeSpace / 1048576}    ; FormatString="N0";};
$fmtPerc  =@{label= "Free %"     ; alignment="right" ;width=10; Expression={100.0 * $_.FreeSpace / $_.Size}; FormatString="N1";};

$disks = Get-WmiObject -ComputerName $server -Class Win32_LogicalDisk -Filter "DriveType = 3";
   
Write-Output ("Server name: {0}`tDrives count #: {1}" -f $server, $disks.Count);
Write-Output $disks | Format-Table $fmtDrive, $fmtName, $fmtSize, $fmtFree, $fmtPerc;

$exportList = @()

foreach ($disk in $disks) {

    $PercentFreeSpace = [math]::Round((100* $disk.FreeSpace / $disk.Size))

    if ($PercentFreeSpace -gt 15) {
        $exportList += [PSCustomObject] @{
            ` Name        = $server
            ` Drive        = $disk.DeviceID; 
            ` VolumeName   = $disk.VolumeName; 
            ` Size         = [math]::Round(($disk.Size / (1048576 * 1000)),0); 
            ` FreeSpace    = [math]::Round(($disk.FreeSpace / (1048576 * 1000))); 
            ` PercentFree  = [math]::Round((100* $disk.FreeSpace / $disk.Size))};
    }
}

$style = "
<style>
    TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
    TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
    TD{border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
</style>
"
$header = "[INFO]<html><body> <div><br> </br>Disk space<br> </br>"
if ($exportList.Length -ne 0) {
    $listOfSpaceHTML = $exportList | ConvertTo-HTML -AS Table -Fragment -PreContent $style | Out-String
    $HTML = ConvertTo-HTML -head $header -Body $listOfSpaceHTML

    $HTML | Out-File -FilePath "path\DiskSpace.html"
}