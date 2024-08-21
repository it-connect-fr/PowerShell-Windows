# Synopsis : This script creates firewall rules to block specific IPv6-related protocols.
# Created by : Dakhama Mehdi
# Version : 1.0
# Date : 08/2024

# List of protocol numbers and their descriptions
$protocolNumbers = @{
    '41' = 'IPv6'
    '43' = 'Route Header'
    '44' = 'Fragment Header'
    '58' = 'ICMPv6'
    '59' = 'No Next Header'
    '60' = 'Destination Options'
}

# Loop through each protocol number in the dictionary
foreach ($nprotocole in $protocolNumbers.Keys) {
    $protocolName = $protocolNumbers[$nprotocole]

    try {
        # Create inbound rule
        New-NetFirewallRule -DisplayName "No-ipv6 Protocol $protocolName Inbound" -Direction Inbound -Action Block -Protocol $nprotocole -LocalPort Any -RemotePort Any
        Write-Output "Inbound rule for $protocolName ($nprotocole) created successfully."
    } catch {
        Write-Error "Failed to create inbound rule for $protocolName ($nprotocole). Error: $_"
    }

    try {
        # Create outbound rule
        New-NetFirewallRule -DisplayName "No-ipv6 Protocol $protocolName Outbound" -Direction Outbound -Action Block -Protocol $nprotocole -LocalPort Any -RemotePort Any
        Write-Output "Outbound rule for $protocolName ($nprotocole) created successfully." 
    } catch {
        Write-Error "Failed to create outbound rule for $protocolName ($nprotocole). Error: $_"
    }
}
