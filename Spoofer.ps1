# Copyright (c) 2026 Kholoudbendriss (Smofeng, sswdwsw)
# SPDX-License-Identifier: Apache-2.0
# License: https://github.com/kholoudbendriss/SpooferMyRust/blob/main/LICENSE

<#
.SYNOPSIS
    Randomizes machine identifiers including MachineGuid, Hostname, and MAC addresses.

.DESCRIPTION
    This script modifies registry keys and system settings to spoof various hardware and OS identifiers.
    It generates a new GUID for the machine, assigns a random desktop hostname, and randomizes MAC 
    addresses for physical network adapters.

.NOTES
    Author: Kholoudbendriss (Smofeng, sswdwsw)
#>

#Requires -RunAsAdministrator
#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Configuration
$LogFilePath = Join-Path -Path $env:TEMP -ChildPath "spoofer_execution_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Write-Output $LogEntry
    Add-Content -Path $LogFilePath -Value $LogEntry
}

function Invoke-RandomizeMachineGuid {
    [CmdletBinding()]
    param ()
    
    $NewGuid = [guid]::NewGuid().ToString()
    Write-Log -Message "Generated new MachineGuid: $NewGuid"
    
    try {
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name 'MachineGuid' -Value $NewGuid -ErrorAction Stop
        Write-Log -Message "Successfully updated MachineGuid in registry."
    } catch {
        Write-Log -Message "Failed to update MachineGuid: $_" -Level 'ERROR'
        throw
    }
}

function Invoke-RandomizeHostname {
    [CmdletBinding()]
    param ()
    
    $Chars = (65..90) + (48..57)
    $RandomSuffix = -join ($Chars | Get-Random -Count 7 | ForEach-Object { [char]$_ })
    $NewHostname = "DESKTOP-$RandomSuffix"
    
    Write-Log -Message "Generated new Hostname: $NewHostname"
    
    try {
        Rename-Computer -NewName $NewHostname -Force -ErrorAction Stop
        Write-Log -Message "Successfully renamed computer."
    } catch {
        Write-Log -Message "Failed to rename computer: $_" -Level 'ERROR'
        throw
    }
}

function Invoke-RandomizeMacAddresses {
    [CmdletBinding()]
    param ()
    
    $NetAdapters = Get-NetAdapter | Where-Object { $_.HardwareInterface -eq $true }
    $RegBase = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}'
    
    if (-not $NetAdapters) {
        Write-Log -Message "No physical network adapters found." -Level 'WARN'
        return
    }

    foreach ($Adapter in $NetAdapters) {
        # Valid starting bytes for a locally administered MAC address
        $FirstByte = ('02', '06', '0A', '0E') | Get-Random
        $RemainingBytes = (1..5) | ForEach-Object { '{0:X2}' -f (Get-Random -Minimum 0 -Maximum 256) }
        $NewMac = $FirstByte + ($RemainingBytes -join '')
        
        Write-Log -Message "Randomizing MAC for $($Adapter.Name) [$($Adapter.InterfaceDescription)] -> $NewMac"
        
        try {
            $ClassKeys = Get-ChildItem -Path $RegBase -ErrorAction Stop
            $Updated = $false
            
            foreach ($Key in $ClassKeys) {
                $DriverDesc = (Get-ItemProperty -Path $Key.PSPath -Name 'DriverDesc' -ErrorAction SilentlyContinue).DriverDesc
                
                if ($DriverDesc -eq $Adapter.InterfaceDescription) {
                    Set-ItemProperty -Path $Key.PSPath -Name 'NetworkAddress' -Value $NewMac -ErrorAction Stop
                    Write-Log -Message "Updated NetworkAddress in registry path: $($Key.PSPath)"
                    $Updated = $true
                    break
                }
            }
            
            if ($Updated) {
                Write-Log -Message "Restarting network adapter: $($Adapter.Name)"
                Restart-NetAdapter -Name $Adapter.Name -Confirm:$false -ErrorAction Stop
            } else {
                Write-Log -Message "Could not locate registry key for adapter: $($Adapter.Name)" -Level 'WARN'
            }
        } catch {
            Write-Log -Message "Failed to randomize MAC for $($Adapter.Name): $_" -Level 'ERROR'
        }
    }
}

function Main {
    try {
        Write-Log -Message "Starting system randomization process."
        
        Invoke-RandomizeMachineGuid
        Invoke-RandomizeHostname
        Invoke-RandomizeMacAddresses
        
        Write-Log -Message "Randomization process completed successfully."
    } catch {
        Write-Log -Message "A fatal error occurred during execution: $_" -Level 'ERROR'
        Exit 1
    }
}

Main
