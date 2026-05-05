# PART 1: SYSTEM USAGE

# CPU Usage
$cpu = Get-Counter '\Processor(_Total)\% Processor Time'
$cpuUsage = [math]::Round($cpu.CounterSamples.CookedValue, 2)

# Memory Usage
$os = Get-CimInstance Win32_OperatingSystem
$totalMem = $os.TotalVisibleMemorySize
$freeMem = $os.FreePhysicalMemory
$usedMem = $totalMem - $freeMem
$memUsage = [math]::Round(($usedMem / $totalMem) * 100, 2)

# Disk Usage (C:)
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$totalDisk = $disk.Size
$freeDisk = $disk.FreeSpace
$usedDisk = $totalDisk - $freeDisk
$diskUsage = [math]::Round(($usedDisk / $totalDisk) * 100, 2)

# Create object for report
$systemStats = [PSCustomObject]@{
    CPU_Usage_Percent    = "$cpuUsage%"
    Memory_Usage_Percent = "$memUsage%"
    Disk_Usage_Percent   = "$diskUsage%"
}

# PART 2: SERVICE STATUS (OPTIMIZED)

# Get all services once
$services = Get-Service
$cimServices = Get-CimInstance Win32_Service

# Create a lookup table for fast matching
$cimLookup = @{}
foreach ($cim in $cimServices) {
    $cimLookup[$cim.Name] = $cim.StartMode
}

$serviceReport = foreach ($svc in $services) {
    $startup = $cimLookup[$svc.Name]

    [PSCustomObject]@{
        ServiceName = $svc.Name
        Status      = $svc.Status
        StartupType = $startup
        Warning     = if ($startup -eq "Auto" -and $svc.Status -ne "Running") {
            "WARNING: Should be running"
        } else {
            ""
        }
    }
}

# PART 3: EVENT LOG CHECK (OPTIMIZED)

$startTime = (Get-Date).AddHours(-24)

$events = Get-WinEvent -FilterHashtable @{
    LogName   = @("System", "Application")
    Level     = 1,2   # Critical & Error
    StartTime = $startTime
} -MaxEvents 50 -ErrorAction SilentlyContinue

$eventReport = if ($events) {
    foreach ($event in $events) {
        [PSCustomObject]@{
            Time    = $event.TimeCreated
            Log     = $event.LogName
            ID      = $event.Id
            Level   = $event.LevelDisplayName
            Message = ($event.Message -replace "`r`n", " ")
        }
    }
} else {
    [PSCustomObject]@{
        Time    = "N/A"
        Log     = "N/A"
        ID      = "N/A"
        Level   = "Info"
        Message = "No critical or error events in the last 24 hours"
    }
}

# HTML STYLE

$style = @"
<style>
body { font-family: Arial; }
h1 { color: #2E8C1F; }
table { border-collapse: collapse; width: 80%; margin-bottom: 20px; }
th, td { border: 1px solid black; padding: 8px; text-align: left; }
th { background-color: #f2f2f2; }
</style>
"@

# HTML BODY

$body = @"
<h1>PC Health Report</h1>
<p>Generated: $(Get-Date)</p>

<h2>System Usage Summary</h2>
$($systemStats | ConvertTo-Html -Fragment)

<h2>Service Status Report</h2>
$($serviceReport | ConvertTo-Html -Fragment)

<h2>Critical/Error Events (Last 24 Hours)</h2>
$($eventReport | ConvertTo-Html -Fragment)
"@

# EXPORT REPORT

$outputPath = "C:\Users\jackm\Desktop\HealthReport.html"

ConvertTo-Html -Head $style -Body $body |
Out-File $outputPath

# Auto-open report
Start-Process $outputPath