[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null
[System.Reflection.Assembly]::LoadFrom("assembly\System.Windows.Interactivity.dll") |Out-Null
[System.Reflection.Assembly]::LoadFrom("assembly\MaterialDesignThemes.Wpf.dll") |Out-Null
[System.Reflection.Assembly]::LoadFrom("assembly\MaterialDesignColors.dll") |Out-Null

$Global:pathPanel = split-path -parent $MyInvocation.MyCommand.Definition
function LoadXaml ($filename) {
    $XamlLoader = (New-Object System.Xml.XmlDocument)
    $XamlLoader.Load($filename)
    return $XamlLoader
}
$XamlMainWindow = LoadXaml("$Global:pathPanel\MonProjet.xaml")
$reader = (New-Object System.Xml.XmlNodeReader $XamlMainWindow)
$Form = [Windows.Markup.XamlReader]::Load($reader)

$XamlMainWindow.SelectNodes("//*[@Name]") | % {
    try { Set-Variable -Name "$("WPF_"+$_.Name)" -Value $Form.FindName($_.Name) -ErrorAction Stop }
    catch { throw }
}

Function Get-FormVariables {
    if ($global:ReadmeDisplay -ne $true) { Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow; $global:ReadmeDisplay = $true }
    write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
    get-variable *WPF*
}

#Get-FormVariables

function Get-ADUserLastLogon {

    [CmdletBinding()]
    
    param(
        [Parameter(Mandatory = $true)][ValidateScript({ Get-ADUser $_ })]$Identity = $null
    )

    # Récupérer la liste de tous les DC du domaine AD
    $DCList = Get-ADDomainController -Filter * | Sort-Object Name | Select-Object Name

    # Initialiser le LastLogon sur $null comme point de départ
    $TargetUserLastLogon = $null
   
    # Date par défaut
    $DefaultDate = [Datetime]'01/01/1601 01:00:00'
        
    Foreach ($DC in $DCList) {

        $DCName = $DC.Name
 
        Try {
            
            # Récupérer la valeur de l'attribut lastLogon à partir d'un DC (chaque DC tour à tour)
            $LastLogonDC = Get-ADUser -Identity $Identity -Properties lastLogon -Server $DCName

            # Convertir la valeur au format date/heure
            $LastLogon = [Datetime]::FromFileTime($LastLogonDC.lastLogon)

            # Si la valeur obtenue est plus récente que celle contenue dans $TargetUserLastLogon
            # la variable est actualisée : ceci assure d'avoir le lastLogon le plus récent à la fin du traitement
            If ($LastLogon -gt $TargetUserLastLogon) {
                $TargetUserLastLogon = $LastLogon
            }
 
            # Nettoyer la variable
            Clear-Variable LastLogon
        }

        Catch {
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }

    if ($TargetUserLastLogon -eq $DefaultDate) {
        return "Jamais"
    }
    else {
        return $TargetUserLastLogon.ToString(" dd/MM/yyyy à HH:mm:ss ")
    }
            
}
$WPF_Label.Content = "Active Directory - LastLogon - $((Get-ADDomain).DNSRoot)"


Get-ADUser -Filter { Enabled -eq $true } | Select-Object samAccountName | Foreach {

    [void]$WPF_MonComboBox.Items.Add($_.SamAccountName) 

}

$WPF_MonBouton.Add_Click(

    {
        if ($WPF_MonComboBox.selectedItem -ne $null) {
            $LastLogonOfUser = Get-ADUserLastLogon -Identity $($WPF_MonComboBox.selectedItem)
            $WPF_Label2.Content = "Dernière connexion de $($WPF_MonComboBox.selectedItem) : $LastLogonOfUser"
        }
    }
)


$Form.ShowDialog() | Out-Null

