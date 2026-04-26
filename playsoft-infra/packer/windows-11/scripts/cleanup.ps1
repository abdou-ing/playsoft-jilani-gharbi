# Cleanup script before sysprep
Write-Host "Running cleanup tasks..."

# Clear temp files
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Users\*\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Clear Windows Update cache
Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
Start-Service wuauserv -ErrorAction SilentlyContinue

# Clear event logs
wevtutil el | Foreach-Object {wevtutil cl "$_"}

# Optimize drive
Optimize-Volume -DriveLetter C -Defrag -Verbose

Write-Host "Cleanup completed"