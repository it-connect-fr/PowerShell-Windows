<#
.SYNOPSIS
    This script analyzes the “info” attribute of Windows 10 computers in the Active Directory, to generate a Windows 11 compatibility report.

.DESCRIPTION
    This script helps you get an overall view of the Windows 11 compatibility of a set of computers, thanks to an HTML report comprising several graphs.

.AUTHOR
    Florian Burnel - IT-Connect.fr

.VERSION
    1.0 - Initial version.

.NOTES
    Filename: Get-ADHardwareReadinessReport.ps1
    Creation Date: 2025/02/18
#>
if (Get-Module -ListAvailable -Name PSWriteHtml) {
    Write-Output "Prerequisite - Module PSWriteHtml : OK"
} else {
    Write-Output "Prerequisite - Module PSWriteHtml : Not found"
    Write-Output "Prerequisite - Module PSWriteHtml : Installation will start..."
    Install-Module PSWriteHtml -Confirm:$false -Force
}

$ReportFolder = "C:\Scripts\HTML\"
$ReportName = "Report-Windows-11-Readiness-$(Get-Date -Format yyyyMMdd_hhmm).html"
$ReportPath = ($ReportFolder).TrimEnd("\") + "\" + $ReportName

Write-Output "Report file : $ReportPath"
Write-Output "Report generation in progress, please wait..."

# Get a list of Windows 10 computers in the Active Directory
$ADComputersWin10 = Get-ADComputer -Filter {OperatingSystem -like "Windows 10*"} -Property OperatingSystem, Info | Sort-Object Name


# Get the list of Windows 10 computers and the result of the compatibility test
$ComputersW11Readiness = $ADComputersWin10 | Select-Object Name, @{ 
                                                    Name="Result"; 
                                                    Expression={
                                                        $JsonObject = $_.Info | ConvertFrom-Json
                                                        if ($JsonObject.returnResult -ne $null){ $JsonObject.returnResult }else{ "EMPTY" }
                                                    }
                                                }, @{ 
                                                    Name="Reason"; 
                                                    Expression={
                                                        $JsonObject = $_.Info | ConvertFrom-Json
                                                        if($JsonObject.returnReason -ne $null){ ($JsonObject.returnReason).TrimEnd(", ") }else{ "" }
                                                    }
                                                }

# Counting by status
$ComputersW11ReadinessStats = $ComputersW11Readiness | Group-Object -Property Result | Sort-Object Count -Descending


# Counting occurrences of different reasons
$ReasonCounts = @{}

$ComputersW11Readiness | ForEach-Object {
    $Reasons = $_.Reason -split ", "
    foreach ($Reason in $Reasons) {
        if (-not [string]::IsNullOrWhiteSpace($Reason)) {
            if ($ReasonCounts.ContainsKey($Reason)) {
                $ReasonCounts[$Reason]++
            } else {
                $ReasonCounts[$Reason] = 1
            }
        }
    }
}

# HTML report construction with PSWriteHTML
New-HTML -Title "Compatibility of computers with Windows 11" -FilePath $ReportPath -ShowHTML:$true {
    
    # Report header with domain name and date
    New-HTMLHeader {
        New-HTMLSection -Invisible  {            
            New-HTMLPanel -Invisible {
                New-HTMLText -Text "Domain : $($env:USERDNSDOMAIN)" -FontSize 18 -FontWeight 100
                New-HTMLText -Text "Date : $(Get-Date -Format "dd/MM/yyyy")" -FontSize 12
            } -AlignContentText left
        }
    }

    # Section 1 - Graphs
    New-HTMLSection -HeaderText "Compatibility with Windows 11" -HeaderBackGroundColor "#00698e" {
        New-HTMLChart -Title "Compatibility of all IT assets" -Gradient {
            foreach ($Line in $ComputersW11ReadinessStats) {
                New-ChartDonut -Name  $Line.Name -Value $Line.Count
            }
        }

        New-HTMLChart -Title "Reasons for incompatibility" -Gradient {
            foreach ($Reason in $ReasonCounts.Keys) {
                New-ChartDonut -Name $Reason -Value $ReasonCounts[$Reason]
            }
        }
    }

    # Section 2 - Computer list tables
    New-HTMLSection -HeaderText "Results of computer compatibility tests" -HeaderBackGroundColor "#00698e"  {
            New-HTMLPanel {
                New-HTMLTable -DataTable $ComputersW11Readiness -HideFooter -AutoSize
            }
    }
}