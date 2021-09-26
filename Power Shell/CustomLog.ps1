$loopCount = 15
$source = 'MyCustomLog1'
while ($count -le $loopCount) {
    $errorCode = Get-Random -Minimum 1000 -Maximum 3999
    if ($errorCode -le 1999) {
        $errorMessage = 'Working as expected' 
    }
    elseif ($errorCode -le 2999) {
        $errorMessage = 'System warning'
    }
    else {
        $errorMessage = 'System Error'
    }
    $logEntry = "$(get-date -format 'MM/dd/yy HH:mm:ss') Source: $source ErrorCode: $errorCode ErrorMessage: $errorMessage" 
    Out-File -InputObject $logEntry -filePath .\MyCustomLog1.log -Append -Encoding utf8
    Start-Sleep -Seconds 7
    $count = $count += 1
}