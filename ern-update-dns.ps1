#Requires -RunAsAdministrator
function Write-Message {
  param(
    [string]$Message,
    [string]$Type = "INFO"
  )

  $timeStamp = Get-Date -Format "HH:mm:ss"
  switch ($Type) {
    "SUCCESS" { $color = "Green" }
    "ERROR" { $color = "Red" }
    "WARNING" { $color = "Yellow" }
    default { $color = "Cyan" }
  }

  Write-Host "[$timeStamp] $Message" -ForegroundColor $color
}

# Function to extract IPs from nslookup output
function Get-IPsFromNslookup {
  param([string]$Hostname)

  try {
    $output = nslookup $Hostname 2>$null

    # Parse IPv4 addresses from the output
    $ips = @()
    foreach ($line in ($output -split "`n")) {
      if ($line -match 'Addresses:') {
        $found = $true
        # Извлекаем IP из той же строки, если он есть
        if ($line -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}') {
          $ips += $matches[0]
        }
      }
      elseif ($found) {
        if ($line -match '^\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})') {
          $ips += $matches[1]
        }
        elseif (-not [string]::IsNullOrWhiteSpace($line) -and $line -notmatch '^\s*\d') {
          break
        }
      }
    }

    if ($ips.Count -eq 0) {
      Write-Message "No IP addresses found in nslookup output" "ERROR"
      return $null
    }

    Write-Message "Found IP addresses: $($ips -join ', ')"
    return $ips
  }
  catch {
    Write-Message "Failed to execute nslookup: $_" "ERROR"
    return $null
  }
}

# Function to test IP with curl
function Test-IPWithCurl {
  param([string]$IP)

  try {
    Write-Message "Testing IP: $IP"
    $result = curl.exe -k -m 2 "$IP`:10901" 2>$null

    if ($LASTEXITCODE -eq 0 -or $result) {
      Write-Message "IP $IP is accessible" "SUCCESS"
      return $true
    }
    else {
      Write-Message "IP $IP is not accessible" "WARNING"
      return $false
    }
  }
  catch {
    Write-Message "Error testing IP $IP : $_" "ERROR"
    return $false
  }
}

# Function to update hosts file
function Update-HostsFile {
  param(
    [string]$Hostname,
    [string]$IP
  )

  $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"

  # Read current content
  $content = Get-Content $hostsPath -ErrorAction Stop

  # Remove old entries for this hostname
  $newContent = @()
  $pattern = "^\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+$([regex]::Escape($Hostname))"

  foreach ($line in $content) {
    if ($line -notmatch $pattern) {
      $newContent += $line
    }
  }

  # Add new entry
  $newContent += "$IP`t$Hostname"

  # Write back to file
  $newContent | Out-File -Encoding ascii $hostsPath -Force

  Write-Message "Hosts file updated: $IP -> $Hostname" "SUCCESS"
}
# Main execution
$hostname = "cl-prod-app-steam.fromsoftware-game.net"
Write-Message "Starting DNS update script for $hostname" "INFO"

# Step 1: Get IPs from nslookup

$ips = Get-IPsFromNslookup -Hostname $hostname

if (-not $ips) {
  Write-Message "Script terminated. No IPs to process." "ERROR"
  exit 1
}

# Step 2: Test each IP
$workingIP = $null
foreach ($ip in $ips) {
  if (Test-IPWithCurl -IP $ip) {
    $workingIP = $ip
    break
  }
}

if (-not $workingIP) {
  Write-Message "No working IP addresses found. Script terminated." "ERROR"
  exit 1
}



# Step 3: Update hosts file
try {
    Update-HostsFile -Hostname $hostname -IP $workingIP
    Write-Message "Script completed successfully!" "SUCCESS"
}
catch {
    Write-Message "Failed to update hosts file: $_" "ERROR"
    exit 1
}

# Optional: Display the new DNS resolution
Write-Message "Verifying new configuration..." "INFO"
try {
    $verify = [System.Net.Dns]::GetHostAddresses($hostname)
    Write-Message "Current resolution for $hostname : $($verify.IPAddressToString -join ', ')" "SUCCESS"
}
catch {
    Write-Message "Verification failed (may need to wait for DNS cache refresh)" "WARNING"
}