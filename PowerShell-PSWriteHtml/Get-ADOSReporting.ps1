<#
.SYNOPSIS
    Exemple d'utilisation du module PSWriteHtml - Rapport Active Directory : répartition par type d'OS

.AUTHOR
    Florian Burnel - IT-Connect.fr

.VERSION
    1.0 - Initial version.

.NOTES
    Filename: Get-ADOSReporting.ps1
    Creation Date: 2025/02/01
#>
# Récupération des données

# Mettre en mémoire la liste des ordinateurs présents dans AD
$ComputersList = Get-ADComputer -Filter * -Properties Name, OperatingSystem, whenCreated, IPv4Address

# Compter les occurrences de chaque OS
$ComputersOSName = $ComputersList | Group-Object -Property OperatingSystem | Sort-Object Count -Descending

# Classification des OS avec une propriété calculée
$ComputersOSType = $ComputersList | Select-Object OperatingSystem, @{ 
                        Name="TypeOS"; 
                        Expression={
                            if ($_.OperatingSystem -match "Windows Server") { "Windows Server" }
                            else { "Windows Desktop" }
                        }
                    } | Group-Object -Property TypeOS | Sort-Object Count -Descending

# Propriétés à exporter pour les tableaux de machines
$ComputersOSProperties = @("Name", "OperatingSystem", "IPv4Address", "whenCreated")
# Récupérer la liste des postes de travail
$ComputersOSDesktop = $ComputersList | Select-Object $ComputersOSProperties | Sort-Object Name | Where-Object { $_.OperatingSystem -NotMatch "Server" }

# Récupérer la liste des serveurs
$ComputersOSServer = $ComputersList | Select-Object $ComputersOSProperties | Sort-Object Name | Where-Object { $_.OperatingSystem -Match "Windows Server" }

# Construction du rapport HTML avec PSWriteHTML
New-HTML -Title "Répartition des OS" -FilePath "C:\Scripts\HTML\RapportOS-2.html" -ShowHTML:$true {
    
    # En-tête du rapport avec le nom du domaine et la date
    New-HTMLHeader {
        New-HTMLSection -Invisible  {            
            New-HTMLPanel -Invisible {
                New-HTMLText -Text "Domaine : $($env:USERDNSDOMAIN)" -FontSize 18 -FontWeight 100
                New-HTMLText -Text "Date : $(Get-Date -Format "dd/MM/yyyy")" -FontSize 12
            } -AlignContentText left
        }
    }

    # Section 1 - Graphes
    New-HTMLSection -HeaderText "Distribution des OS dans Active Directory" -HeaderBackGroundColor "#00698e" {
        New-HTMLChart -Title "Répartition par OS" -Gradient {
            foreach ($Line in $ComputersOSName) {
                New-ChartDonut -Name  $Line.Name -Value $Line.Count
            }
        }
        New-HTMLChart -Title "Répartition Desktop / Server" -Gradient {
            foreach ($Line in $ComputersOSType) {
                New-ChartDonut -Name $Line.Name -Value $Line.Count
            }
        }
    }

    # Section 2 - Tableaux avec la liste des ordinateurs
    New-HTMLSection -HeaderText "Liste des machines inscrites dans l'Active Directory" -HeaderBackGroundColor "#00698e"  {
            New-HTMLPanel {
                New-HTMLTable -DataTable $ComputersOSDesktop -HideFooter -AutoSize
            }
            New-HTMLPanel {
                New-HTMLTable -Title "Liste des postes des serveurs" -DataTable $ComputersOSServer -HideFooter -AutoSize
            }
    }
}





