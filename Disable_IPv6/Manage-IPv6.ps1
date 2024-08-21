<#
.SYNOPSIS
    This PowerShell script manages IPv6 settings on network adapters. It provides functions to enable or disable IPv6 bindings based on the specified conditions.

.DESCRIPTION
    This script offers functions to disable and enable IPv6 bindings on all network adapters. It includes functionality to disable IPv6 only if the adapter does not have an assigned IPv6 address.
    It is designed to facilitate the management of IPv6 configurations on Windows machines, allowing fine control based on the state of each adapter.

.PARAMETER Disable-IPv6Adapter
    This function disables IPv6 on all network adapters unless an IPv6 address is already assigned.

.PARAMETER Enable-IPv6Adapter
    This function enables IPv6 on all network adapters if it is not already enabled.

.AUTHOR
    Dakhama Mehdi

.CONTRIBUTORS
    IT-Connect

.VERSION
    1.0 - Initial version.

.NOTES
    Filename: Manage-IPv6.ps1
    Creation Date: 08/2024
#>

# Define the path of the log file with the current date and time
$logDirectory = "C:\temp"
$logFileName = "IPv6Adapter.log"
$logerrorFileName = "IPv6Adapter_other.log"
$logPath = Join-Path -Path $logDirectory -ChildPath $logFileName
$logPathother = Join-Path -Path $logDirectory -ChildPath $logerrorFileName

# Function to write to the log file
function Write-Log {
    param (
        [string]$Message,
        [string]$Type = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$timestamp [$Type] $Message" | Out-File -FilePath $logPath -Append
}

function New-Log {
    param (
        [string]$Message,
        [string]$Type = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$timestamp [$Type] $Message" | Out-File -FilePath $logPathother
}

function Disable-IPv6Adapter {
    Get-NetAdapter | ForEach-Object {
        $adapterName = $_.Name
        $ipv6Binding = Get-NetAdapterBinding -Name $adapterName -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
        
        if ($ipv6Binding) {
            if ($ipv6Binding.Enabled) {
                try {
                    Write-Log "Starting IPv6 disabling on all adapters."
                    Disable-NetAdapterBinding -Name $adapterName -ComponentID ms_tcpip6 -Confirm:$false
                    Write-Log "IPv6 has been disabled on adapter '$adapterName'."
                    Write-Log "Finished IPv6 disabling."
                } catch {
                    Write-Log "Error occurred while disabling IPv6 on adapter '$adapterName': $_" -Type 'ERROR'
                }
            } else {
                New-Log "IPv6 is already disabled on adapter '$adapterName'."
            }
        } else {
            New-Log "Adapter '$adapterName' does not support IPv6."
        }
    }   
}

function Enable-IPv6Adapter {
    
    Get-NetAdapter | ForEach-Object {
        $adapterName = $_.Name
        $ipv6Binding = Get-NetAdapterBinding -Name $adapterName -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue

        if ($ipv6Binding) {
            if (-not $ipv6Binding.Enabled) {
                try {
                    Write-Log "Starting IPv6 disabling on all adapters."
                    Enable-NetAdapterBinding -Name $adapterName -ComponentID ms_tcpip6 -Confirm:$false
                    Write-Log "IPv6 has been disabled on adapter '$adapterName'."
                    Write-Log "Finished IPv6 disabling."
                } catch {
                    Write-Log "Error occurred while disabling IPv6 on adapter '$adapterName': $_" -Type 'ERROR'
                }
            } else {
                New-Log "IPv6 is already disabled on adapter '$adapterName'."
            }
        } else {
            New-Log "Adapter '$adapterName' does not support IPv6."
        }
    }
   
}


#Pls Uncomment one function Disable or Enable, By default Disable is used.

Disable-IPv6Adapter
#Enable-IPv6Adapter