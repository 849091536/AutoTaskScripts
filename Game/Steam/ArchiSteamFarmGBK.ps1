<##
 # Author: Cyanashi(imwhtl@gmail.com)
 # Version: 2.0.2
 # Last_Updated: 2020-04-02
 # Description: ArchiSteamFarm ASF�Զ�����ű�
 #>

$psVersion = ([String]$psversiontable.PSVersion).Substring(0, 3)
if ([Double]$psVersion -lt 5) {
    Write-Host "[Warn] PowerShell �汾���ͣ�$($psVersion)�����˽ű���֧�� 5.1 ���µİ汾��" -ForegroundColor Yellow
    exit
}

$Script:Version = "2.0.2"
$Script:Updated = "2020-04-02"
$Script:ASFVersion = ""
$got_zip = $false
$got_exe = $false
$desktop = [System.Environment]::GetFolderPath('Desktop')
$workspace = Split-Path -Parent $MyInvocation.MyCommand.Definition
$zipPath = $workspace + '\ASF-win-x64.zip'
$corePath = $workspace + '\core'
$7zPath = $env:ProgramFiles + '\7-Zip\7z.exe'
Set-Location $workspace
Add-Type -AssemblyName System.Windows.Forms
function Get-MsgBox {
    param (
        [String]$Prompt = "Ĭ������",
        [System.Windows.Forms.MessageBoxButtons]$Buttons = [System.Windows.Forms.MessageBoxButtons]::OK,
        [String]$Title = "Ĭ�ϱ���",
        [System.Windows.Forms.MessageBoxIcon]$Icon = [System.Windows.Forms.MessageBoxIcon]::None
    )
    return [System.Windows.Forms.MessageBox]::Show($Prompt, $Title, $Buttons, $Icon)
}
function Copy-Files {
    [CmdletBinding()]
    param (
        [String]$origin_folder = "",
        [String]$new_folder = "",
        [Switch]$force
    )
    $files = Get-ChildItem $origin_folder -Recurse
    foreach ($item in $files) {
        if ($item.fullname -like "*appsettings.json*") { continue }
        $new_item = $item.fullname.Replace($origin_folder, $new_folder) # ȡ����·��
        # ���Ŀ���ļ����������ж��¾�
        if (Test-Path $new_item) {
            # �����Ŀ¼������ ��������� ��ᴴ��һ����Ŀ¼
            if (-not ((Get-ChildItem $new_item).PSIsContainer)) {
                # ���Ŀ��λ�ô��� [�޸�ʱ������Դ�ļ���] �ļ� �����¿���������
                if ($force -or (Get-ChildItem $new_item).lastwritetime -lt $item.lastwritetime) { Copy-Item $item.fullname $new_item -Force }
            }
        }
        # ���Ŀ���ļ�������ֱ�ӿ���
        Else { Copy-Item $item.fullname $new_item }
    }
}
function Get-DownloadUrl {
    $response = Invoke-WebRequest -URI "https://api.github.com/repos/JustArchiNET/ArchiSteamFarm/releases/latest" -UseBasicParsing | Select-Object -ExpandProperty Content | ConvertFrom-Json
    if ($null -eq $response) { return "" }
    else {
        $response.assets | ForEach-Object {
            if ($_.browser_download_url.Contains('win')) { return $_.browser_download_url }
        }
    }
}
function Test-ZipFile {
    if (Test-Path $zipPath) { return $true }
    else { return $false }
}
function Test-ASF {
    if (Test-Path $corePath) {
        Get-ChildItem $corePath | ForEach-Object -Process {
            if ($_ -is [System.IO.FileInfo] -and $_.name -eq "ArchiSteamFarm.exe") { return $true }
        }
        return $false
    }
    else { return $false }
}
function Get-ZipFile {
    if (Test-ZipFile) {
        $downloadConfirm = Get-MsgBox -Title "ѹ�����Ѵ���" -Prompt "��⵽��ǰĿ¼���Ѵ��� ASF-win-x64.zip �ļ����Ƿ��������أ�" -Buttons YesNo  -Icon Warning
        if ($downloadConfirm -eq 'No') { return $true }
    }
    $assetUrl = Get-DownloadUrl
    if ([String]::IsNullOrEmpty($assetUrl)) {
        Write-Host "[Error] ��ȡ�����ȶ������ص�ַʧ�ܣ��������硣��ǰ�� https://github.com/JustArchiNET/ArchiSteamFarm/releases �ֶ�������ȷ�汾��ASF-win-x64.zip����" -ForegroundColor Red
        Read-Host "���»س�������" | Out-Null
        if (-not (Test-ZipFile)) { return $false }
    }
    $Script:ASFVersion = (($assetUrl -split "download/")[1] -split "/ASF-win-x64.zip")[0]
    Write-Host "[Info] ��ʼ���� ArchiSteamFarm Version �����ȶ��� $($Script:ASFVersion) ѹ���� [ASF-win-x64.zip]..."
    if (Test-Path 'ASF-win-x64.tmp') { Remove-Item 'ASF-win-x64.tmp' }
    Invoke-WebRequest -URI $assetUrl -OutFile 'ASF-win-x64.tmp'
    if (Test-Path $zipPath) { Remove-Item $zipPath }
    Rename-Item "$($workspace)\ASF-win-x64.tmp" $zipPath
    if (Test-ZipFile) {
        Write-Host "[Info] ArchiSteamFarm v$($Script:ASFVersion) ������ɣ�λ�� $($zipPath) ��" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "[Error] ArchiSteamFarm v$($Script:ASFVersion) ����ʧ�ܣ������ԡ����߷��� $($assetUrl) �ֶ����ء�" -ForegroundColor Red
        return $false
    }
}
function Expand-ZipFile {
    Write-Host "[Info] ��ʼ��ѹ ArchiSteamFarm Version ѹ���� $($Script:ASFVersion) [ASF-win-x64.zip]..."
    if (Test-Path $7zPath) {
        Set-Alias sz $7zPath
        sz x "$zipPath" -y -o"$corePath"
        Write-Host "[Info] [ASF-win-x64.zip] ��ѹ�ɹ�����ѹ���ļ�λ�� $corePath ��" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "[Warn] δ��Ĭ��Ŀ¼ $7zPath �ҵ� 7-Zip ����`n       ��ָ�� 7-Zip ������\7-Zip\7z.exe��·�������ֶ���ѹ $zipPath ��" -ForegroundColor Yellow
        return $false
    }
}
function Get-FileReady {
    if (Test-ASF) { return }
    else {
        do {
            # Read-Host "[Debug] WTF" | Out-Null
            if (Get-ZipFile) {
                $got_zip = $true
                do {
                    if (Expand-ZipFile) {
                        $got_exe = $true
                        if (Test-ASF) { return }
                        else {
                            Write-Host "[Fatal] û���� $($workspace)\core �ҵ� ArchiSteamFarm ���������һֱ������������뱸�ݺ������ļ���ɾ�� .\core �ļ��к����ԡ�" -BackgroundColor Red
                            exit
                        }
                    }
                    else {
                        if (Test-ASF) { return }
                        else {
                            $7zPath = Read-Host "���� 7-Zip ������·��"
                            Write-Host $7zPath
                            if (-not $7zPath.ToLower().EndsWith('.exe')) { $7zPath = $7zPath.TrimEnd('\/') + "\7z.exe" }
                        }
                    }
                } while (-not $got_exe)
            }
        } while (-not $got_zip)
    }
}
function Import-Config {
    if (Test-Path "$($workspace)\config") {
        $importConfirm = Get-MsgBox -Title "׼�����������ļ�" -Prompt "�����������з��ֳ�ͻ���ļ����Ƿ�ǿ�Ƹ��ǣ�`n��ѡ�񡸷񡹣���ᱣ�������н��µĲ��֡�" -Buttons YesNoCancel -Icon Question
        if ($importConfirm -eq 'Cancel') { Write-Host "[Info] ȡ��Ӧ�������ļ���" }
        else {
            # Write-Host "$($workspace)\config >> $($corePath)\config" -ForegroundColor Yellow
            if ($importConfirm -eq 'Yes') { Copy-Files "$($workspace)\config" "$($corePath)\config" -Force }
            elseif ($importConfirm -eq 'No') { Copy-Files "$($workspace)\config" "$($corePath)\config" }
            Write-Host "[Info] ��Ӧ�������ļ���" -ForegroundColor Green
        }
    }
}
function New-Shortcut {
    $shortcutPath
    $shortcutTip
    $shortcutConfirm = Get-MsgBox -Title "׼��������ݷ�ʽ" -Prompt "�Ƿ������洴����ݷ�ʽ��`n��ѡ�񡸷񡹣�����ڡ��ű�����Ŀ¼��������ݷ�ʽ��" -Buttons YesNoCancel -Icon Question
    if ($shortcutConfirm -eq 'Yes') {
        $shortcuts = "$($desktop)\ASF.lnk", "$($corePath)\ArchiSteamFarm.exe", "$($desktop)\ASF Config.lnk", "$($corePath)\config", "����"
    }
    elseif ($shortcutConfirm -eq 'No') {
        $shortcuts = "$($workspace)\ASF.lnk", "$($corePath)\ArchiSteamFarm.exe", "$($workspace)\ASF Config.lnk", "$($corePath)\config", "�˽ű�ͬ��Ŀ¼��"
    }
    elseif ($shortcutConfirm -eq 'Cancel') {
        Write-Host "[Info] ȡ��������ؿ�ݷ�ʽ��"
        return
    }
    $shell = New-Object -ComObject WScript.Shell
    $i = 0
    while ($i -lt 4) {
        $lnk = $shell.CreateShortcut($shortcuts[$i++])
        $lnk.TargetPath = $shortcuts[$i++]
        $lnk.Save()
    }
    Write-Host "[Info] ��ؿ�ݷ�ʽ�ѽ�����λ��$($shortcuts[4])��" -ForegroundColor Green
}
function Exit-WithAnyKey {
    Write-Host "[Info] ������������ɣ���������رմ��ڡ�"
    [Console]::Readkey() | Out-Null
    exit
}
function Backup-Config {
    if (Test-ASF) {
        $backupConfirm = Get-MsgBox -Title "���������ļ�" -Prompt "�Ƿ񱸷ݵ�ǰ�����ļ���" -Buttons YesNo  -Icon Warning
        if ($backupConfirm -eq 'Yes') {
            if (-not (Test-Path "$($workspace)\backup")) { New-Item -ItemType Directory "$($workspace)\backup" }
            $current = Get-Date -Format 'yyyyMMdd_HHmmss'
            Compress-Archive -Path "$($corePath)\config" -DestinationPath "$($workspace)\backup\config_���ñ���_$($current)" -Force
        }
    }
}

Write-Host "[Info] �ű���ǰ�汾v$($Script:Version) $($Script:Updated)" -ForegroundColor Cyan
Backup-Config
Get-FileReady
Write-Host "[Info] ArchiSteamFarm ������׼����ɡ�" -ForegroundColor Cyan
Import-Config
Start-Sleep -Milliseconds 500
New-Shortcut
Exit-WithAnyKey
