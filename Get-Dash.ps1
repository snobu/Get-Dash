# Author: adrianc@oriflame.net

Clear-Host
$build = 6
Write-Host -BackgroundColor DarkCyan -ForegroundColor Cyan "DC2 VM Dashboard - Build $build", "`n"

$Computers = 'DC2-HYPER1', 'DC2-HYPER2'

Invoke-Command -ComputerName $Computers -ScriptBlock {
        $avg = Get-WmiObject win32_processor | 
                   Measure-Object -property LoadPercentage -Average | 
                   Foreach {$_.Average}
        $mem = Get-WmiObject win32_operatingsystem |
                   Foreach {[Math]::Round((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) *100 / $_.TotalVisibleMemorySize))}
        $freeC = Get-WmiObject Win32_Volume -Filter "DriveLetter = 'C:'" |
                     Foreach {[Math]::Round($_.FreeSpace / $_.Capacity * 100)}
        $freeD = Get-WmiObject Win32_Volume -Filter "DriveLetter = 'D:'" |
                     Foreach {[Math]::Round($_.FreeSpace / $_.Capacity * 100)}
        $network = (Get-NetLbfoTeam).Status
        [PSCustomObject][Ordered] @{
             HyperV_Host = $env:COMPUTERNAME
             AvgCPUPercent = $avg
             MemUsagePercent = $mem
             C_Volume_UsagePercent = 100-[int]$freeC
             D_Volume_UsagePercent = 100-[int]$freeD
             Network = $network
        }
} | Select HyperV_Host,
           @{l='AvgCPU(%)';e={$_.AvgCPUPercent}}, 
           @{l='MemUsage(%)';e={$_.MemUsagePercent}}, 
           @{l='C_Vol_Usage(%)';e={$_.C_Volume_UsagePercent}},
           @{l='D_Vol_Usage(%)';e={$_.D_Volume_UsagePercent}},
           Network | ft -AutoSize

Invoke-Command -ComputerName $Computers -scriptblock {
    Get-VM | Foreach-Object {
                $vm = $_
                $measure = measure-vm $vm
                [PSCustomObject][ordered] @{
                    VMName = $vm.VMName
                    NowCPU_MHz = $vm.CPUUsage
                    AvgCPU_MHz = $measure.AvgCPU
                    AvgIOPS = $measure.AggregatedAverageNormalizedIOPS
                    Mem_MB = ($vm.MemoryAssigned)/1mb
                    TotalDisk_GB = [Math]::Round($measure.TotalDisk/1024)
                    Uptime = $vm.Uptime
                    Host = $vm.ComputerName
                    State = $vm.State
                    ReplState = $vm.ReplicationState
                    Heartbeat = $vm.Heartbeat
                } #psobject
             } #foreach
} | select VMName, State, Host, ReplState, Mem_MB, AvgCPU_MHz, NowCPU_MHz, AvgIOPS, Uptime, TotalDisk_GB, Heartbeat | sort State | ft -AutoSize

Pause
