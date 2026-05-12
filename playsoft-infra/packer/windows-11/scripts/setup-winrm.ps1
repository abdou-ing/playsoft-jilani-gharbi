# Enable WinRM for Packer
Write-Host "Setting up WinRM..."

# Enable WinRM service
Enable-PSRemoting -Force
winrm quickconfig -q
winrm quickconfig -transport:http

# Configure WinRM
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="800"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/client/auth '@{Basic="true"}'

# Configure firewall
netsh advfirewall firewall set rule group="Windows Remote Management" new enable=yes
netsh advfirewall firewall add rule name="WinRM HTTP" protocol=TCP dir=in localport=5985 action=allow

# Restart WinRM
Restart-Service winrm

Write-Host "WinRM setup completed"