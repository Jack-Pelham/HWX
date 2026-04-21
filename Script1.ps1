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

Write-Host "CPU Usage: $cpuUsage%"
Write-Host "Memory Usage: $memUsage%"
Write-Host "Disk Usage (C: drive): $diskUsage%"