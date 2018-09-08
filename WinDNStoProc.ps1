Param
(
	[alias("Enable")][switch]$e = $False,
	[alias("Historical")][switch]$history = $False,
	[alias("Interval")][int32]$i = 1,
	[alias("Process")][string]$p = "",
	[alias("Request")][string]$r = ""
)

$dnsclog = New-Object System.Diagnostics.Eventing.Reader.EventLogConfiguration "Microsoft-Windows-DNS-Client/Operational"
$status = $dnsclog.IsEnabled
[console]::TreatControlCAsInput = $true
$run = $True
$h = @{" " = " "}
$l = @{}

function enableDNSClog
{
	Write-Output("Enabling DNS Client Operational Logging...")
	$dnsclog.IsEnabled = $true
	$dnsclog.SaveChanges()
}


function disableDNSClog
{
	Write-Output("Disabling DNS Client Operational Logging...")
	$dnsclog.IsEnabled = $false
	$dnsclog.SaveChanges()
}

function mergeHashTables
{
	$l.Keys | % -Process{if(!$h.Contains($_)){$h[$_] = $l.Item($_)}}
}

function getReqInfo
{
	#$l = New-Object System.Collections.ArrayList
	$req = ""
	$procid = ""
	$proc = ""
	$time = ""
	$evs = Get-WinEvent $dnsclog.LogName | where Id -eq 3006 | where TimeCreated -ge $date
	$evs | % -Process { try { $time = $_.TimeCreated;$procid = $_.ProcessID;$proc = (Get-Process -pid $_.ProcessId).Path;$req = ([xml]$_.ToXml()).SelectSingleNode("//*[@Name='QueryName']")."#text";if (!$h.Contains("$req `r`n     Process Path: $proc `r`n     PID: $procid")){$l["$req `r`n     Process Path: $proc `r`n     PID: $procid"] = $time}}catch{ Write-Output "Couldnt't resolve process."}}
  
    $l.Keys | % -Process { $x = $l.Item($_); Write-Output "$_ `r`n     Created: $x `r`n" }
	mergeHashTables($l,$h)
	$l.clear()
}

if (!$status)
{
	if(!$e)
	{
		Write-Output "DNS Client Operational logging is not currently enabled. Defaulting to enabling the logging only while this script is running and then disabling it when the script closes. To enable DNS Client Operational logging and leave it enabled, run this script again with the '-e' parameter."
	}
	enableDNSClog
}

if ($history)
{
	$date = "1/1/1950 12:00:00 AM"
}
else
{
	$date = Get-Date
}

while ($run)
{
	getReqInfo
	if($Host.UI.RawUI.KeyAvailable -and (3 -eq  [int]$Host.UI.RawUI.ReadKey("AllowCtrlC,IncludeKeyUp,NoEcho").Character))
	{
		$run = $False
	}
	Sleep($i)
}

if (!$e)
{
	disableDNSClog
}