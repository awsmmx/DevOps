Param (            
[string[]]$Address = $(1..20 | ForEach-Object{"192.168.1.$_"}),            
[int]$Threads = 5            
)            
            
Write-host "Distributing addresses around jobs"            
$JobAddresses = @{}            
$CurJob = 0            
$CurAddress = 0            
while ($CurAddress -lt $Address.count)            
{            
    $JobAddresses[$CurJob] += @($Address[$CurAddress])            
    $CurAddress++            
    if ($CurJob -eq $Threads -1)            
    {            
        $CurJob = 0            
    }            
    else            
    {            
        $CurJob++            
    }            
}            
            
$Jobs = @()            
foreach ($n in 0 .. ($Threads-1))            
{            
    Write-host "Starting job $n, for addresses $($JobAddresses[$n])"            
    $Jobs += Start-Job -ArgumentList $JobAddresses[$n] -ScriptBlock {            
        $ping = new-object System.Net.NetworkInformation.Ping            
        Foreach ($Ip in $Args)            
        {            
            trap {            
                new-object psobject -Property {            
                    Status = "Error: $_"            
                    Address = $Ip            
                    RoundtripTime = 0            
                }            
                Continue            
            }            
            $ping.send($Ip,100) | Select-Object `
                @{name="Status"; expression={$_.Status.ToString()}},             
                @{name = "Address"; expression={$Ip}}, RoundtripTime            
        }            
    }            
}            
            
write-host "Waiting for jobs"            
$ReceivedJobs = 0            
while ($ReceivedJobs -le $Jobs.Count)            
{            
    foreach ($CompletedJob in ($Jobs | Where-Object {$_.State -eq "Completed"}))            
    {            
        Receive-Job $CompletedJob | Select-Object status, address, roundtriptime            
        $ReceivedJobs ++            
        Start-Sleep 1            
    }            
}            
            
Remove-Job $Jobs            
write-host "Done."