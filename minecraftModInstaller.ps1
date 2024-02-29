Add-Type -AssemblyName 'System.Windows.Forms' -PassThru | Select-Object -ExpandProperty Assembly | Select-Object -ExpandProperty FullName -Unique

$MinecraftPath = '~/AppData/Roaming/.minecraft'
$MinecraftVersion = '1.20.1'
$FabricVersion = '0.15.6'
$FabricDirName = 'fabric-loader-' + $FabricVersion + '-' + $MinecraftVersion
$FabricUrl = 'https://maven.fabricmc.net/net/fabricmc/fabric-installer/1.0.0/fabric-installer-1.0.0.jar'

$AppName = 'MinecraftModInstaller'
$FabricInstallerFileName = 'fabric-installer-1.0.0.jar'

$ContextPath = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
$WebClient = New-Object System.Net.WebClient

function ExitWithMessage {
    param ($Message, $Type = 'Error')

    if ($Type -eq 'Success') {
        $Icon = 'Information'
        $Title = 'Sukces'
    }

    if ($Type -eq 'Error') {
        $Icon = $Type
        $Title = 'Blad'
    }

    [System.Windows.Forms.MessageBox]::Show($Message, $Title, 'OK', $Icon)
    exit 0
}

# Get $MinecraftPath
if (!$(Test-Path -Path $MinecraftPath -ErrorAction SilentlyContinue)) {
    $DirBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $DirBrowser.Description = 'Wybierz folder danych Minecrafta'
    $DirBrowser.RootFolder = 'ApplicationData'

    if ($DirBrowser.ShowDialog() -eq 'OK') {
        $MinecraftPath = $DirBrowser.SelectedPath
    } else {
        ExitWithMessage -Message 'Folder Minecrafta jest konieczny do instalacji modow'
    }
}

$MinecraftDir = Get-Item -Path $MinecraftPath
$FabricDir = $MinecraftDir.GetDirectories('versions').GetDirectories($FabricDirName)
$ModDir = $MinecraftDir.GetDirectories('mods')

# Install Fabric
if ($FabricDir) {
    Write-Output 'Fabric found'
} else {
    $FabricInstallerPath = $ContextPath + '/' + $FabricInstallerFileName

    $WebClient.DownloadFile($FabricUrl, $FabricInstallerPath)

    java -jar $FabricInstallerPath client -mcversion $MinecraftVersion -loader $FabricVersion
    Write-Output 'Fabric installed'

    Remove-Item -Path $FabricInstallerPath
}

# Clear mods directory
if ([System.Windows.Forms.MessageBox]::Show('Chcesz usunac obecnie zainstalowane mody?', $AppName, 'YesNo', 'Question', 'Button1') -eq 'Yes') {
    $ModDir.GetFiles() | ForEach-Object { $_.Delete()}
    Write-Output 'mods cleared'
} else {
    Write-Output 'mods leaved'
}

# Get
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
$FileBrowser.Title = 'Wybierz plik zip z modami'
$FileBrowser.InitialDirectory = $ContextPath
$FileBrowser.CheckFileExists = $true
$FileBrowser.DefaultExt = 'zip'
$FileBrowser.Filter = 'zip files (*.zip)|*.zip'

if ($FileBrowser.ShowDialog() -eq 'OK') {
    $ZipPath = $FileBrowser.FileName
    Write-Output 'zip selected'
} else {
    ExitWithMessage -Message 'Nie podano pliku z modami'
}

# Open zip and copy mods
Expand-Archive -Path $ZipPath -DestinationPath $ModDir.FullName -Force

Write-Output 'mods copied'
ExitWithMessage -Type 'Success' -Message 'Instalacja modow zakonczona sukcesem'