param ([string[]]$Servers, [int]$Count=-1, $Timeout=1)
$pinger = New-Object system.net.networkinformation.ping
$ErrorActionPreference = "SilentlyContinue"

for ($n=0; $n -lt $Count -or $Count -eq -1; $n++)
{
    
    $Obj = new-object psobject
    
    $Obj | add-member -type noteproperty -name "Time" -value (get-date -format "hh:mm:ss")
   
    foreach ($Server in $Servers)
    {
        
        trap {$Obj | add-member -type noteproperty -name $Server -value "Error"}
        
        $res = $pinger.Send($Server,($Timeout*1000))
        
        if ($res.Status -eq "Success")
        {
            
            $Value = $res.RoundtripTime
        }
        else
        {
            
            $Value = $res.status
        }
        
        $Obj | add-member -type noteproperty -name $Server -value $Value
    }
    
    $Obj
}