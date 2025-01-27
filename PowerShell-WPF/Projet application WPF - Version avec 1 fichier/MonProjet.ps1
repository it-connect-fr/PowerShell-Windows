[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null

[xml]$XamlMainWindow = @"
<Window
   xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
   xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
   Width="480"
   Height="200"
   Title="IT Connect WPF">
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
</Window>
"@ 

$reader=(New-Object System.Xml.XmlNodeReader $XamlMainWindow)
$form=[Windows.Markup.XamlReader]::Load( $reader )

$Global:pathPanel= split-path -parent $MyInvocation.MyCommand.Definition

$XamlMainWindow.SelectNodes("//*[@Name]") | %{
    try {Set-Variable -Name "$("WPF_"+$_.Name)" -Value $Form.FindName($_.Name) -ErrorAction Stop}
    catch{throw}
    }

Function Get-FormVariables{
if ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true}
write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
get-variable *WPF*
}
#Get-FormVariables


$Form.ShowDialog() | Out-Null