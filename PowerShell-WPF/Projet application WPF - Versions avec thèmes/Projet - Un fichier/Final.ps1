[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null
[System.Reflection.Assembly]::LoadFrom("assembly\MahApps.Metro.dll")       				| out-null
[System.Reflection.Assembly]::LoadFrom("assembly\MahApps.Metro.IconPacks.dll")      | out-null  
[System.Reflection.Assembly]::LoadFrom("assembly\ControlzEx.dll")      | out-null  
[System.Reflection.Assembly]::LoadFrom("assembly\Microsoft.Xaml.Behaviors.dll")      | out-null  

[xml]$XamlMainWindow = @"
<Controls:MetroWindow
      xmlns:Controls="clr-namespace:MahApps.Metro.Controls;assembly=MahApps.Metro"
      xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"		
		xmlns:iconPacks="http://metro.mahapps.com/winfx/xaml/iconpacks" 				
   Width="480"
   Height="200"
   Title="IT Connect WPF"
	WindowStartupLocation="CenterScreen"
   ResizeMode="CanMinimize"
	WindowStyle="None" 	
	BorderBrush="Black"
	GlowBrush="{DynamicResource AccentColorBrush}"	
	Topmost="True">

	<Window.Resources>
        <ResourceDictionary>
            <ResourceDictionary.MergedDictionaries>
                <ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Controls.xaml" />
                <ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Fonts.xaml" />
                <ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Themes/Light.Orange.xaml" />
            </ResourceDictionary.MergedDictionaries>
        </ResourceDictionary>
    </Window.Resources>	

<Controls:MetroWindow.RightWindowCommands>
	<Controls:WindowCommands>
	   <Button Name="Change" >
			<iconPacks:PackIconOcticons Kind="Paintcan" Margin="0,5,0,0" ToolTip="Change le thème de l'application"/>													
		</Button>	
	</Controls:WindowCommands>	
</Controls:MetroWindow.RightWindowCommands>

  <Grid>
      <StackPanel HorizontalAlignment="Center" Margin="0,10,0,0" Orientation="Vertical">
         <Label Name="Label" HorizontalAlignment="Center" Content="Active Directory" FontSize="20"/>
         <GroupBox 
            Width="400"
            Height="90"
            Margin="0,10,0,0"
            Header="Utilisateurs du domaine">
            <StackPanel HorizontalAlignment="Center" Margin="0" Orientation="Vertical">
            <StackPanel HorizontalAlignment="Center" Margin="0,10,0,0" Orientation="Horizontal">
               <Button
                  Name="MonBouton"
                  Width="80"
                  Height="20"
                  Margin="0 10 0 0"
                  Content="Check"/>
               <ComboBox Name="MonComboBox" Width="200" Height="20"  Margin="5 10 0 0"  />
            </StackPanel>
            <Label Name="Label2" Content="" Foreground="green"/>
            </StackPanel>
         </GroupBox>
      </StackPanel>
   </Grid>
</Controls:MetroWindow>
"@ 


$Global:pathPanel = split-path -parent $MyInvocation.MyCommand.Definition

$reader=(New-Object System.Xml.XmlNodeReader $XamlMainWindow)
$form=[Windows.Markup.XamlReader]::Load( $reader )

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

$WPF_change.Add_Click({
	$Theme = [ControlzEx.Theming.ThemeManager]::Current.DetectTheme($form)
    $my_theme = ($Theme.BaseColorScheme)
	If($my_theme -eq "Light")
		{
            [ControlzEx.Theming.ThemeManager]::Current.ChangeThemeBaseColor($form,"Dark")
				
		}
	ElseIf($my_theme -eq "Dark")
		{					
            [ControlzEx.Theming.ThemeManager]::Current.ChangeThemeBaseColor($form,"Light")
		}		
})


$Form.ShowDialog() | Out-Null

