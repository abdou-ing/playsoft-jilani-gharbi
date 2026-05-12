# Ensure student user exists with admin privileges
Write-Host "Configuring student user..."

# Check if user exists
$userExists = Get-LocalUser -Name "student" -ErrorAction SilentlyContinue

if (-not $userExists) {
    Write-Host "Creating student user..."
    $Password = ConvertTo-SecureString "123456" -AsPlainText -Force
    New-LocalUser "student" -Password $Password -FullName "Student User" -Description "Student Account with Admin Privileges"
    Add-LocalGroupMember -Group "Administrators" -Member "student"
} else {
    Write-Host "Student user already exists"
    # Ensure password is set correctly
    $Password = ConvertTo-SecureString "123456" -AsPlainText -Force
    Set-LocalUser -Name "student" -Password $Password
    
    # Ensure user is in Administrators group
    $isAdmin = (Get-LocalGroupMember -Group "Administrators" -Member "student" -ErrorAction SilentlyContinue)
    if (-not $isAdmin) {
        Add-LocalGroupMember -Group "Administrators" -Member "student"
    }
}

# Set password to never expire
Set-LocalUser -Name "student" -PasswordNeverExpires $true

# Enable account if disabled
Enable-LocalUser -Name "student"

Write-Host "Student user configured successfully"