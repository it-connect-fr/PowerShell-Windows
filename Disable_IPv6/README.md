# Disable IPv6 to Mitigate CVE-2024-38063 -Author : Mehdi DAKHAMA

## Overview

This project provides PowerShell scripts designed to disable IPv6 on Windows network adapters, helping mitigate the risks associated with CVE-2024-38063.

## Scripts

- **Firewall_DisableIpv6.PS1**: Creates outbound and inbound firewall rules to disable all IPv6 traffic.
- **Manage-IPv6.ps1**: Disables IPv6 on all network adapters and creates a log. By default, this script disables IPv6, but you can re-enable it by uncommenting `#enable` and commenting `disable`.

## Usage

1. Download or copy the scripts.
2. Execute `Firewall_DisableIpv6.PS1` to apply firewall rules on a elevated Powershell (run as admin)
3. Run `Manage-IPv6.ps1` to disable IPv6 on all network adapters on a elevated Powershell (run as admin)

## Deployment via GPO

1. Place the scripts on a shared network location accessible by target machines.
2. Create a new Group Policy Object (GPO) in your domain.
3. Under `Computer Configuration -> Policies -> Windows Settings -> Scripts`, add the script path to either Startup or Shutdown scripts.
4. Link the GPO to the relevant Organizational Units (OUs) where you want to apply the IPv6 disabling policies.

## CVE Association

These scripts are specifically designed to address vulnerabilities related to [CVE-2024-38063](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2024-38063).

## Contribution

Contributions are welcome through pull requests or issue reports.

## License

This project is licensed under the MIT License. See the `LICENSE` file for more details.
