# Check if the script is running on PowerShell 7 or later
if ($PSVersionTable.PSVersion.Major -lt 7 -or ($PSVersionTable.PSVersion.Major -eq 7 -and $PSVersionTable.PSVersion.Minor -lt 5)) {
    Write-Host "This script requires PowerShell 7.5 or later. Please upgrade your PowerShell version." -ForegroundColor Red
    exit
}

# Define the xaml code for the window
[xml]$xaml = @'
<Window
 xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 				
   Width="480"
   Height="350"
   Title="IT Connect WPF Pwsh 7.5"
	ThemeMode="System"
   WindowStartupLocation="CenterScreen"
   ResizeMode="CanMinimize"
	Topmost="True">

  <DockPanel>
      <Button Name="Switch" Content="Switch Theme" 
              Margin="10" 
              HorizontalAlignment="Right" 
              VerticalAlignment="Top" 
              DockPanel.Dock="Top"
              Style="{DynamicResource AccentButtonStyle}"/>
      <Grid>
         <StackPanel HorizontalAlignment="Center" Margin="0,10,0,0" Orientation="Vertical">
            <Label Name="Label" HorizontalAlignment="Center" Content="Active Directory" FontSize="20" BorderBrush="Black"
	Foreground="{DynamicResource AccentTextFillColorPrimaryBrush}"/>
            <GroupBox 
               Width="400"
               Height="100"
               Margin="0,10,0,0"
               Header="Utilisateurs du domaine">
               <StackPanel HorizontalAlignment="Center" Margin="0" Orientation="Vertical">
                  <StackPanel HorizontalAlignment="Center" Margin="0,10,0,0" Orientation="Horizontal">
                     <Button
                        Name="MonBouton"
                        Width="80"
                        Height="35"
                        Margin="0 10 0 0"
                        Content="Check"
                        Style="{DynamicResource AccentButtonStyle}"/>
                     <ComboBox Name="MonComboBox" Width="200" Margin="5 10 0 0" SelectedIndex="0"  />
                  </StackPanel>
                  <Label Name="Label2" Content="" Margin="5" Foreground="{DynamicResource AccentTextFillColorPrimaryBrush}"/>
               </StackPanel>
            </GroupBox>
         </StackPanel>
      </Grid>
   </DockPanel>
</Window>
'@

# Charger l'assembly WPF
Add-Type -AssemblyName PresentationFramework

# Charger la fenêtre et les éléments nommés en tant que variables dans une table de hachage
$UI = [System.Collections.Hashtable]::Synchronized(@{})
$UI.Window = [System.Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $xaml))
$xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | 
    ForEach-Object -Process {
        $UI.$($_.Name) = $UI.Window.FindName($_.Name)
    }

# Amener la fenêtre au premier plan
$UI.Window.Add_Loaded({
    $This.Activate()
})


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
$UI.Label.Content = "Active Directory - LastLogon - $((Get-ADDomain).DNSRoot)"


# Remplir la ComboBox avec les données des utilisateurs
Get-ADUser -Filter { Enabled -eq $true } | Select-Object samAccountName | Foreach {
    $ComboBoxItem = New-Object System.Windows.Controls.ComboBoxItem
    $ComboBoxItem.Content = $_.SamAccountName
    $ComboBoxItem.HorizontalContentAlignment = 'Stretch' 
    [void]$UI.MonComboBox.Items.Add($ComboBoxItem)
}

$UI.MonBouton.Add_Click(
    {
        # Assurez-vous que l'élément sélectionné n'est pas nul et récupérez son contenu
        if ($UI.MonComboBox.SelectedItem -ne $null) {
            $SelectedUser = $UI.MonComboBox.SelectedItem.Content
            if ($SelectedUser -ne $null) {
                $LastLogonOfUser = Get-ADUserLastLogon -Identity $SelectedUser
                $UI.Label2.Content = "Dernière connexion de $SelectedUser : $LastLogonOfUser"
            } else {
                $UI.Label2.Content = "Aucun utilisateur sélectionné."
            }
        } else {
            $UI.Label2.Content = "Aucun utilisateur sélectionné."
        }
    }
)


# Ajouter un événement de clic au bouton Switch
$UI.Switch.Add_Click({
    if ($UI.Window.ThemeMode -eq "Dark") {
        $UI.Window.ThemeMode = "Light"
        $UI.Switch.Content = "Switch to Dark"
    } else {
        $UI.Window.ThemeMode = "Dark"
        $UI.Switch.Content = "Switch to Light"
    }
})

# Définir le texte initial pour le bouton Switch en fonction du thème actuel
if ($UI.Window.ThemeMode -eq "Dark") {
    $UI.Switch.Content = "Switch to Light"
} else {
    $UI.Switch.Content = "Switch to Dark"
}

# Show the window
[void]$UI.Window.ShowDialog()