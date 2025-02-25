[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null

[xml]$MonXAML = @"
<Window
   xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
   xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
   Width="380"
   Height="200"
   Title="IT Connect WPF">
   <Grid>
      <StackPanel HorizontalAlignment="Center" Margin="0,10,0,0" Orientation="Vertical">
         <Label HorizontalAlignment="Center" Content="Active Directory" FontSize="20"/>
         <GroupBox
            Width="300"
            Height="65"
            Margin="0,10,0,0"
            Header="Active Directory">
            <StackPanel HorizontalAlignment="Center" Margin="0,0,0,0" Orientation="Horizontal">
               <Button
                  Name="MonBouton"
                  Width="80"
                  Height="20"
                  Content="Search"/>
               <ComboBox Name="MonComboBox" Width="200" Height="20"/>
            </StackPanel>
         </GroupBox>
      </StackPanel>
   </Grid>
</Window>
"@ 

$reader=(New-Object System.Xml.XmlNodeReader $MonXAML)
$MonInterface=[Windows.Markup.XamlReader]::Load( $reader )
$MonBouton = $Interface.FindName("MonBouton") 
$MonTextBox = $Interface.FindName("MonComboBox") 
$MonInterface.ShowDialog() | Out-Null
