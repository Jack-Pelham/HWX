#CPU 
$cpu = Get-Counter '\Processor(_Total)\% Processor Time'
$cpuUsage = [math]::Round($cpu.CounterSamples.CookedValue, 2)

#Memory Usage
$os = Get-CimInstance win32_OperatingSystem
$totalMem = $os.TotalVisibleMemorySize
$freeMem = $os.FreePhysicalMemory
$usedMem = $totalMem - $freeMem
$memUsage = [math]::Round(($usedMem / $totalMem) * 100, 2)

#Disk Usage (C: Drive)
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$totalDisk = $disk.Size
$freeDisk = $disk.FreeSpace
$usedDisk = $totalDisk - $freeDisk
$diskUsage = [math]::Round(($usedDisk / $totalDisk) * 100, 2)

#couldn't do write-host as it only shows in console, not report, so I wrapped the values

#create structured object from calculated values
$systemStats = [PSCustomObject]@{
	CPU_Usage_Percent = "$cpuUsage%"
	Memory_Usage_Percent = "$memUsage%"
	Disk_Usage_Percent = "$diskUsage%"

#Start doing 2nd part of script here

#This is the start of the fourth part
}
#CSS for better view
$style = @"
<style>
body { font-family: Arial; }
h1 { color: #2E8C1; }
table { border-collapse: collapse; width: 50%; }
th, td { border: 1px solid black; padding: 8px; text-allign: left; }
th { background-color: #f2f2f2; } 
</style>
"@

#HTML Body
$body = @"
<h1>PC Health Report</h1>
<p>Generated: $(Get-Date)</p>

<h2>System Usage Summary</h2>
$($systemStats | ConvertTo-Html -Fragment)
"@

Converto-Html -Head $style -Body $body | Out-File "C:\Users\jackm\HWX\HealthReport.html"
