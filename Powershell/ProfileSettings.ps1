Invoke-Expression (&starship init powershell)
Import-Module Terminal-Icons
Import-Module PSReadLine
Set-PSReadLineKeyHandler -Key Tab -Function Complete
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'
$PSReadLineOptions = @{
    HistoryNoDuplicates = $true
    HistorySearchCursorMovesToEnd = $true
    MaximumHistoryCount = 20000
    PredictionViewStyle = 'ListView'
    PredictionSource = 'History'
    BellStyle = 'None'
}
Set-PSReadLineOption @PSReadLineOptions

Add-Type -AssemblyName Microsoft.VisualBasic

$OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:FZF_DEFAULT_OPTS = '--height 15'

Set-Alias -Name tt -Value tree
Set-Alias -Name g -Value git
Set-Alias -Name p -Value python
Set-Alias -Name x -Value cls
Set-Alias -Name l -Value less
Set-Alias -Name ex -Value explorer
Set-Alias -Name open -Value start
function y { wsl yazi }
function cpr { code $PROFILE }

function Open-MicroWSL {
    param(
        [Parameter(Mandatory=$false)]
        [string]$FilePath
    )
    if ($FilePath) {
        $wslPath = wsl wslpath -a ($FilePath -replace "\\", "/")
        $fileExists = wsl test -f $wslPath && echo "exists" || echo "not exists"
        $isDirectory = wsl test -d $wslPath && echo "is_directory" || echo "not_directory"
        if ($fileExists -eq "exists" -and $isDirectory -eq "not_directory") {
            wsl micro $wslPath
        } elseif ($isDirectory -eq "is_directory") {
            Write-Host "Cannot open a directory in micro. Please specify a file path."
        } else {
            New-Item -ItemType File -Path $FilePath -Force
            wsl micro $wslPath
        }
    } else {
        wsl micro
    }
}
Set-Alias -Name m -Value Open-MicroWSL

# Добавляем определение для Windows API функции SetForegroundWindow
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class User32 {
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
    }
"@
function Open-Edge {
    $edgeProcess = Get-Process msedge -ErrorAction SilentlyContinue
    if ($edgeProcess) {
        $windowHandle = $edgeProcess | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1 -ExpandProperty MainWindowHandle
        if ($windowHandle) {
            $null = [User32]::SetForegroundWindow($windowHandle)
        }
        else {
            Write-Host "Microsoft Edge запущен, но не удалось найти его окно"
        }
    }
    else {
        Start-Process "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    }
}
Set-Alias -Name edge -Value Open-Edge

# Алиас для подсчета элементов
function Count-Items {
    param(
        [string]$Path = (Get-Location).Path,
        [switch]$f,
        [switch]$d,
        [switch]$h
    )
    $params = @{
        Path = $Path
        Force = (-not $h)
    }
    if ($f) {
        $params['File'] = $true
    }
    elseif ($d) {
        $params['Directory'] = $true
    }
    (Get-ChildItem @params).Count
}
Set-Alias -Name count -Value Count-Items

function Open-Obsidian {
    param (
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Path,
        [switch]$c
    )
    $obsidianPath = "D:\Obsidian\obsidian.exe"
    $vaultPath = "D:\ObsidianVault\Zettelkasten"
    $tempPath = "D:\Temp"
    if (-not (Test-Path $obsidianPath)) {
        Write-Host "Obsidian не найден. Проверьте путь установки" -ForegroundColor Red
        return
    }
    if (-not (Test-Path $tempPath)) {
        New-Item -ItemType Directory -Path $tempPath | Out-Null
    }
    if ($Path.Count -eq 0) {
        Start-Process -FilePath $obsidianPath -NoNewWindow -RedirectStandardOutput "$tempPath\output.log" -RedirectStandardError "$tempPath\error.log"
        Start-Sleep -Seconds 1
        Remove-Item "$tempPath\output.log", "$tempPath\error.log" -ErrorAction SilentlyContinue
    }
    else {
        foreach ($item in $Path) {
            $item = $item.TrimEnd('\')
            $fullPath = $null
            try {
                $fullPath = Convert-Path $item -ErrorAction Stop
            } catch {
                $fullPath = Join-Path (Get-Location) $item
            }
            if (Test-Path $fullPath) {
                if (Test-Path $fullPath -PathType Container) {
                    $destDir = Join-Path $vaultPath ([System.IO.Path]::GetFileName($fullPath))
                    if ($c.IsPresent) {
                        if (Test-Path $destDir) {
                            $counter = 1
                            while (Test-Path (Join-Path $vaultPath ($([System.IO.Path]::GetFileName($fullPath)) + " $counter"))) {
                                $counter++
                            }
                            $destDir = Join-Path $vaultPath ($([System.IO.Path]::GetFileName($fullPath)) + " $counter")
                        }
                        Copy-Item -Path $fullPath -Destination $destDir -Recurse -Force
                    } else {
                        if (-not (Test-Path $destDir)) {
                            Copy-Item -Path $fullPath -Destination $destDir -Recurse -Force
                        }
                    }
                    Start-Process -FilePath $obsidianPath -NoNewWindow -RedirectStandardOutput "$tempPath\output.log" -RedirectStandardError "$tempPath\error.log"
                    Start-Sleep -Seconds 1
                    Remove-Item "$tempPath\output.log", "$tempPath\error.log" -ErrorAction SilentlyContinue
                }
                else {
                    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($fullPath)
                    $fileExtension = [System.IO.Path]::GetExtension($fullPath)
                    $destPath = Join-Path $vaultPath ($fileName + $fileExtension)
                    if ($c.IsPresent) {
                        if (Test-Path $destPath) {
                            $counter = 1
                            while (Test-Path (Join-Path $vaultPath ($fileName + " $counter" + $fileExtension))) {
                                $counter++
                            }
                            $destPath = Join-Path $vaultPath ($fileName + " $counter" + $fileExtension)
                        }
                        Copy-Item -Path $fullPath -Destination $destPath -Force
                    } else {
                        if (-not (Test-Path $destPath)) {
                            Copy-Item -Path $fullPath -Destination $destPath -Force
                        }
                    }
                    $relativePath = [System.IO.Path]::GetRelativePath($vaultPath, $destPath)
                    $encodedVault = [System.Uri]::EscapeDataString([System.IO.Path]::GetFileName($vaultPath))
                    $encodedFile = [System.Uri]::EscapeDataString($relativePath)
                    $uri = "obsidian://open?vault=$encodedVault&file=$encodedFile"
                    Start-Process -FilePath $obsidianPath -ArgumentList $uri -NoNewWindow -RedirectStandardOutput "$tempPath\output.log" -RedirectStandardError "$tempPath\error.log"
                    Start-Sleep -Seconds 1
                    Remove-Item "$tempPath\output.log", "$tempPath\error.log" -ErrorAction SilentlyContinue
                }
            } else {
                Write-Host "Файл или директория не найдены: $item" -ForegroundColor Red
            }
        }
    }
}
Set-Alias -Name ob -Value Open-Obsidian

function d { Set-Location D:\ }
function dev { Set-Location D:\GolangProject }
function devl { Set-Location D:\GolangProject\GoLearning }
function settings { Set-Location D:\Settings }
function conf { Set-Location C:\Users\whosowsee\.config }
function rrad ($command) { Remove-Item $command -Force -Recurse }
function llf { Get-ChildItem -fo }

function Get-ChildItemFo {
    param (
        [string]$Path = "."
    )
    Get-ChildItem -Path $Path -Force | Format-Wide -Column 1
}
Set-Alias -Name ll -Value Get-ChildItemFo

function Get-ChildItemWithoutFo {
    param (
        [string]$Path = "."
    )
    Get-ChildItem -Path $Path | Format-Wide -Column 1
}
Set-Alias -Name lh -Value Get-ChildItemWithoutFo


function Close-Terminal {
  $windows = Get-Process | Where-Object { $_.MainWindowTitle -match "Windows Terminal" }
  foreach ($window in $windows) {
    try {
      $window.CloseMainWindow()
    } catch { }
  }
  Get-Process -Name "WindowsTerminal" -ErrorAction SilentlyContinue | Stop-Process -Force
}
Set-Alias -Name closewt -Value Close-Terminal
Set-Alias -Name exitwt -Value Close-Terminal

function Navigate-ToParentDirectory {
    $currentPath = Get-Location
    $parentPath = Split-Path -Path $currentPath -Parent
    if (-not (Test-Path $currentPath)) {
        Write-Host "Директории не существует" -ForegroundColor Yellow
        while (-not (Test-Path $parentPath) -and $parentPath -ne "") {
            $parentPath = Split-Path -Path $parentPath -Parent
        }
        if ($parentPath -eq "") {
            Write-Host "Переход в корневую директорию" -ForegroundColor Red
            Set-Location \
            return
        }
    }
    try {
        Set-Location $parentPath
    }
    catch {
        Write-Host "Ошибка при переходе в директорию: $_" -ForegroundColor Red
    }
}
Set-Alias -Name cc -Value Navigate-ToParentDirectory

function Recycle-Bin { explorer.exe shell:RecycleBinFolder }
function Open-Downloads { explorer.exe shell:Downloads }
Set-Alias -Name bin -Value Recycle-Bin
Set-Alias -Name dw -Value Open-Downloads

function Rename-Items {
    param (
        [Parameter(Mandatory=$true)]
        [string]$OldName,
        [Parameter(Mandatory=$true)]
        [string]$NewName
    )
    try {
        $FullOldPath = Resolve-Path $OldName -ErrorAction Stop
        $FullNewPath = Join-Path (Split-Path $FullOldPath) $NewName
        if (-not (Test-Path $FullOldPath)) {
            throw "Исходный файл не существует"
        }
        if (Test-Path $FullNewPath) {
            throw "Файл с новым именем уже существует"
        }
        $Acl = Get-Acl $FullOldPath
        Rename-Item -Path $FullOldPath -NewName $NewName -ErrorAction Stop
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        Write-Host "Не удалось найти указанный путь" -ForegroundColor Red
    }
    catch [System.UnauthorizedAccessException] {
        Write-Host "Недосточно прав для переименования" -ForegroundColor Red
    }
    catch {
        Write-Host "$_" -ForegroundColor Red
    }
}
Set-Alias -Name rn -Value Rename-Items

function Remove-ItemToRecycleBin {
    param (
        [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
        [string[]]$path
    )
    process {
        foreach ($p in $path) {
            if (Test-Path -Path $p) {
                try {
                    Add-Type -AssemblyName Microsoft.VisualBasic
                    $item = Get-Item -Path $p -Force
                    if ($item.PSIsContainer) {
                        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($item.FullName, 'OnlyErrorDialogs', 'SendToRecycleBin')
                    } else {
                        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($item.FullName, 'OnlyErrorDialogs', 'SendToRecycleBin')
                    }
                } catch {
                    if ($_.Exception.InnerException.GetType().FullName -eq "System.UnauthorizedAccessException") {
                        Write-Host "Недостаточно прав для удаления: $p" -ForegroundColor Red
                    } else {
                        Write-Host "Не удалось удалить элемент: $p" -ForegroundColor Red
                    }
                }
            } else {
                Write-Host "Путь не найден: $p" -ForegroundColor Yellow
            }
        }
    }
}
Set-Alias -Name rr -Value Remove-ItemToRecycleBin

function Remove-ItemWithAdminRights ($path) {
    if (Test-Path -Path $path) {
        try {
            icacls $path /grant Администраторы:F /inheritance:e | Out-Null
        } catch {
            Write-Host "Ошибка при выдаче прав: $_" -ForegroundColor Red
        }
        try {
            Remove-Item $path -Force -Recurse
        } catch {
            Write-Host "Ошибка при удалении: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Путь не найден: $path" -ForegroundColor Yellow
    }
}
Set-Alias -Name rradr -Value Remove-ItemWithAdminRights

function Copy-Recursively {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Source,
        [Parameter(Mandatory=$false, Position=1)]
        [string]$DestinationOrNewName,
        [Parameter(Mandatory=$false, Position=2)]
        [string]$NewName
    )
    if (-not (Test-Path $Source)) {
        Write-Host "Исходный путь '$Source' не существует" -ForegroundColor Yellow
        return
    }
    $sourceName = Split-Path $Source -Leaf
    $isDirectory = Test-Path $Source -PathType Container
    $currentLocation = (Get-Location).Path
    if ($DestinationOrNewName -and -not $NewName) {
        if ($DestinationOrNewName.Contains([IO.Path]::DirectorySeparatorChar) -or
            $DestinationOrNewName.Contains([IO.Path]::AltDirectorySeparatorChar)) {
            $Destination = $DestinationOrNewName
            $NewName = $null
        } else {
            $Destination = $currentLocation
            $NewName = $DestinationOrNewName
        }
    } elseif ($DestinationOrNewName -and $NewName) {
        $Destination = $DestinationOrNewName
    } else {
        $Destination = $currentLocation
    }
    if ($isDirectory -and $NewName -and $NewName.Contains('.')) {
        Write-Host "Ошибка: Нельзя скопировать директорию '$Source' и назвать её как файл '$NewName'" -ForegroundColor Red
        return
    }
    if (Test-Path $Destination -PathType Leaf) {
        Write-Host "Ошибка: Указанный путь назначения '$Destination' является файлом, а не директорией" -ForegroundColor Red
        return
    }
    if ($NewName) {
        $finalDestination = Join-Path $Destination $NewName
    } else {
        $finalDestination = Join-Path $Destination $sourceName
    }
    if (-not $isDirectory -and (Test-Path $Destination -PathType Container) -and -not $NewName) {
        $finalDestination = Join-Path $Destination $sourceName
    }
    try {
        if ($isDirectory) {
            if (-not (Test-Path $finalDestination)) {
                New-Item -Path $finalDestination -ItemType Directory -Force | Out-Null
            }
            Get-ChildItem -Path $Source -Force | ForEach-Object {
                $destPath = Join-Path $finalDestination $_.Name
                Copy-Item -Path $_.FullName -Destination $destPath -Recurse -Force
            }
        } else {
            $destDir = Split-Path $finalDestination -Parent
            if (-not (Test-Path $destDir)) {
                New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            }
            Copy-Item -Path $Source -Destination $finalDestination -Force
        }
    }
    catch {
        Write-Host "Ошибка при копировании: $_" -ForegroundColor Red
    }
}
Set-Alias -Name cpc -Value Copy-Recursively

function whereis ($command) {
    Get-Command -Name $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

# Создать и перейти в директорию
function New-DirectoryAndEnter {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    try {
        if (Test-Path -Path $Path) {
            Write-Host "Директория '$Path' уже существует" -ForegroundColor Yellow
        } else {
            New-Item -Path $Path -ItemType Directory -ErrorAction Stop | Out-Null
        }
        Set-Location -Path $Path
    } catch {
        Write-Host "Произошла ошибка при создании директории '$Path': $_" -ForegroundColor Red
    }
}
Set-Alias -Name mc -Value New-DirectoryAndEnter

function New-MultipleDirectories {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
        [string[]]$Paths
    )
    $existingDirs = @()
    foreach ($Path in $Paths) {
        if (![string]::IsNullOrWhiteSpace($Path)) {
            if (Test-Path $Path) {
                $existingDirs += $Path
            } else {
                try {
                    New-Item -Path $Path -ItemType Directory -ErrorAction Stop
                }
                catch {
                    Write-Host "Ошибка при создании директории '$Path': $_"
                }
            }
        }
    }
    if ($existingDirs.Count -gt 0) {
        Write-Host "`nСледующие директории уже существуют:" -ForegroundColor Yellow
        $existingDirs | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
    }
}
Set-Alias -Name mdd -Value New-MultipleDirectories

# Удалить текущую директорию (RecycleBin)
function Remove-CurrentDirectoryToRecycleBin {
    $currentPath = Get-Location
    $parentPath = Split-Path -Parent $currentPath
    if ([string]::IsNullOrEmpty($parentPath)) {
        Write-Host "Невозможно удалить корневую директорию" -ForegroundColor Red
        return
    }
    try {
        Set-Location $parentPath -ErrorAction Stop
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory(
            $currentPath,
            'OnlyErrorDialogs',
            'SendToRecycleBin'
        )
    }
    catch [UnauthorizedAccessException] {
        Write-Host "Недостаточно прав для удаления директории" -ForegroundColor Red
        Set-Location $currentPath
    }
    catch {
        Write-Host "$_" -ForegroundColor Yellow
        Set-Location $currentPath
    }
}
Set-Alias -Name rw -Value Remove-CurrentDirectoryToRecycleBin

function Remove-CurrentDirectory {
    $currentPath = Get-Location
    $parentPath = Split-Path -Parent $currentPath

    if ([string]::IsNullOrEmpty($parentPath)) {
        Write-Host "Невозможно удалить корневую директорию"
        return
    }
    Set-Location $parentPath
    try {
        Remove-Item $currentPath -Recurse -Force
    }
    catch {
        Write-Host "$_"
        Set-Location $currentPath
    }
}
Set-Alias -Name rwad -Value Remove-CurrentDirectory

function Move-ItemsAdvanced {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Destination,
        [switch]$f,
        [switch]$d,
        [switch]$h
    )
    if (-not (Test-Path -Path $Destination -PathType Container)) {
        New-Item -Path $Destination -ItemType Directory -Force | Out-Null
        Write-Host "Создана папка назначения: $Destination" -ForegroundColor Green
    }
    $items = if ($h) { Get-ChildItem } else { Get-ChildItem -Force }
    if ($f) {
        $items = $items | Where-Object { !$_.PSIsContainer }
    } elseif ($d) {
        $items = $items | Where-Object { $_.PSIsContainer }
    }
    $sameNameFolderExists = Test-Path -Path (Join-Path (Get-Location).Path (Split-Path $Destination -Leaf))
    $itemCount = if ($sameNameFolderExists) { $items.Count - 1 } else { $items.Count }
    $items | Where-Object { $_.FullName -ne (Resolve-Path $Destination).Path } | ForEach-Object {
        $sourcePath = $_.FullName
        $destPath = Join-Path $Destination $_.Name
        $moveSuccessful = $false
        try {
            if (-not $h) {
                Move-Item -Path $sourcePath -Destination $Destination -Force -ErrorAction Stop
            } else {
                Move-Item -Path $sourcePath -Destination $Destination -ErrorAction Stop
            }
            $moveSuccessful = $true
        } catch {
            if (-not ($_.Exception.Message -like "*Destination path cannot be a subdirectory of the source*")) {
                Write-Host "Не удалось переместить$($_.Name): $_" -ForegroundColor Red
            }
        }
        if (-not $moveSuccessful -and (Test-Path $destPath) -and (Get-Item $destPath).PSIsContainer) {
            try {
                Remove-Item $destPath -Force -Recurse -ErrorAction Stop
            } catch {
                Write-Host "Не удалось удалить пустую директорию ${destPath}: $_" -ForegroundColor Red
            }
        }
    }
    $remainingItems = if ($h) { Get-ChildItem } else { Get-ChildItem -Force }
    if ($f) {
        $remainingItems = $remainingItems | Where-Object { !$_.PSIsContainer }
    } elseif ($d) {
        $remainingItems = $remainingItems | Where-Object { $_.PSIsContainer }
    }
    $movedCount = if ($sameNameFolderExists) { $itemCount + 1 - $remainingItems.Count } else { $itemCount - $remainingItems.Count }

    if ($movedCount -lt $itemCount) {
        Write-Host "Перемещено элементов: $movedCount из $itemCount" -ForegroundColor Green
    } else { }
}
Set-Alias -Name mvi -Value Move-ItemsAdvanced

function Move-ItemsToParent {
    param (
        [switch]$f,
        [switch]$d,
        [switch]$h
    )
    $Destination = (Get-Item -Force ..).FullName
    $items = if ($h) { Get-ChildItem } else { Get-ChildItem -Force }
    if ($f) {
        $items = $items | Where-Object { !$_.PSIsContainer }
    } elseif ($d) {
        $items = $items | Where-Object { $_.PSIsContainer }
    }
    $itemCount = $items.Count
    $items | Where-Object { $_.FullName -ne $PWD.Path -and $_.FullName -ne $Destination } | ForEach-Object {
        $sourcePath = $_.FullName
        $destPath = Join-Path $Destination $_.Name
        $moveSuccessful = $false
        try {
            if (-not $h) {
                Move-Item -Path $sourcePath -Destination $Destination -Force -ErrorAction Stop
            } else {
                Move-Item -Path $sourcePath -Destination $Destination -ErrorAction Stop
            }
            $moveSuccessful = $true
        } catch {
            if (-not ($_.Exception.Message -like "*Destination path cannot be a subdirectory of the source*")) {
                Write-Host "Не удалось переместить$($_.Name): $_" -ForegroundColor Red
            }
        }
        if (-not $moveSuccessful -and (Test-Path $destPath) -and (Get-Item $destPath).PSIsContainer) {
            try {
                Remove-Item $destPath -Force -Recurse -ErrorAction Stop
            } catch {
                Write-Host "Не удалось удалить пустую директорию ${destPath}: $_" -ForegroundColor Red
            }
        }
    }
    $remainingItems = if ($h) { Get-ChildItem } else { Get-ChildItem -Force }
    if ($f) {
        $remainingItems = $remainingItems | Where-Object { !$_.PSIsContainer }
    } elseif ($d) {
        $remainingItems = $remainingItems | Where-Object { $_.PSIsContainer }
    }
    $movedCount = $itemCount - $remainingItems.Count
    if ($movedCount -lt $itemCount) {
        Write-Host "Перемещено элементов: $movedCount из $itemCount" -ForegroundColor Green
    } else { }
}
Set-Alias -Name mvp -Value Move-ItemsToParent

# Открытие Pycharm
function Open-PyCharm {
    param (
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Path
    )
    $pycharmPath = "C:\Program Files\JetBrains\PyCharm 2024.1.2\bin\pycharm64.exe"
    if (-not (Test-Path $pycharmPath)) {
        Write-Host "PyCharm не найден. Проверьте путь установки" -ForegroundColor Red
        return
    }
    if ($Path.Count -eq 0) {
        Start-Process $pycharmPath
    }
    else {
        foreach ($item in $Path) {
            $resolvedPath = Resolve-Path $item -ErrorAction SilentlyContinue
            if ($resolvedPath) {
                & $pycharmPath $resolvedPath
            } else {
                Write-Host "Путь не найден: $item" -ForegroundColor Yellow
            }
        }
    }
}
Set-Alias -Name pch -Value Open-PyCharm

# Открытие Goland
function Open-GoLand {
    param (
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Path
    )
    $golandPath = "C:\Program Files\JetBrains\GoLand 2024.1.4\bin\goland64.exe"
    if (-not (Test-Path $golandPath)) {
        Write-Host "GoLand не найден. Проверьте путь установки" -ForegroundColor Red
        return
    }
    if ($Path.Count -eq 0) {
        Start-Process $golandPath
    }
    else {
        foreach ($item in $Path) {
            $resolvedPath = Resolve-Path $item -ErrorAction SilentlyContinue
            if ($resolvedPath) {
                & $golandPath $resolvedPath
            } else {
                Write-Host "Путь не найден: $item" -ForegroundColor Yellow
            }
        }
    }
}
Set-Alias -Name gld -Value Open-GoLand

# Функция для скрытия файлов и директорий
function Set-ItemHidden {
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string[]]$Path
    )
    process {
        foreach ($item in $Path) {
            $resolvedPath = Resolve-Path $item -ErrorAction SilentlyContinue
            if ($resolvedPath) {
                $item = Get-Item $resolvedPath -Force
                if (-not $item.Attributes.HasFlag([System.IO.FileAttributes]::Hidden)) {
                    $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden
                } else {
                    Write-Host "Элемент уже скрыт" -ForegroundColor Yellow
                }
            } else {
                Write-Host "Путь не найден: $item" -ForegroundColor Red
            }
        }
    }
}
Set-Alias -Name hide -Value Set-ItemHidden

function Remove-ItemsToRecycleBin {
    param (
        [Parameter(Mandatory=$false)]
        [string]$Path = (Get-Location).Path,
        [switch]$f,
        [switch]$d,
        [switch]$h
    )
    $items = if ($h) {
        Get-ChildItem -Path $Path
    } else {
        Get-ChildItem -Path $Path -Force
    }
    if ($f) {
        $items = $items | Where-Object { !$_.PSIsContainer }
    } elseif ($d) {
        $items = $items | Where-Object { $_.PSIsContainer }
    }
    if ($items.Count -eq 0) {
        Write-Host "Нет элементов для удаления в $Path" -ForegroundColor Yellow
        return
    }
    foreach ($item in $items) {
        if ($item.PSIsContainer) {
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory(
                $item.FullName,
                [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
                [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
            )
        } else {
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
                $item.FullName,
                [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
                [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
            )
        }
    }
}
Set-Alias -Name rmi -Value Remove-ItemsToRecycleBin

function New-MultipleItems {
    param (
        [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
        [string[]]$Names
    )
    $existingItems = @()
    foreach ($name in $Names) {
        if (![string]::IsNullOrWhiteSpace($name)) {
            if (Test-Path $name) {
                $existingItems += $name
            } else {
                try {
                    New-Item -Path $name -ItemType File -ErrorAction Stop
                }
                catch {
                    Write-Host "Ошибка при создании файла '$name': $_"
                }
            }
        }
    }
    if ($existingItems.Count -gt 0) {
        Write-Host "`nСледующие файлы уже существуют:" -ForegroundColor Yellow
        $existingItems | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
    }
}
Set-Alias -Name mf -Value New-MultipleItems
Set-Alias -Name ">" -Value New-MultipleItems
Set-Alias -Name touch -Value New-MultipleItems

function Close-PowerShell {[System.Environment]::Exit(0)}
Set-Alias -Name close -Value Close-PowerShell

function Open-ExplorerHere {explorer.exe .}
Set-Alias -Name here -Value Open-ExplorerHere

function Go-Run {go run $args}
function Go-Build {go build $args}
Set-Alias -Name gr -Value Go-Run
Set-Alias -Name gb -Value Go-Build

function Git-Status {git status $args}
function Git-Log {git log $args}
function Git-LsFiles {git ls-files $args}
Set-Alias -Name gitls -Value Git-LsFiles
Set-Alias -Name gits -Value Git-Status
Set-Alias -Name gitl -Value Git-Log

function GitCommitWithMessage {
    param (
        [Parameter(Mandatory=$true)]
        [string]$CommitMessage
    )
    git commit -m "$CommitMessage"
}
Set-Alias -Name gitc -Value GitCommitWithMessage

function GitCommitWithMultipleMessages {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FirstMessage,
        [Parameter(Mandatory=$true)]
        [string]$SecondMessage
    )
    git commit -m "$FirstMessage" -m "$SecondMessage"
}
Set-Alias -Name gitcm -Value GitCommitWithMultipleMessages


# lf icons
$env:LF_ICONS = "tw=:st=:ow=:dt=:di=:fi=:ln=:or=:ex=:*.c=:*.cc=:*.clj=:*.coffee=:*.cpp=:*.txt=:*.css=:*.d=:*.dart=:*.erl=:*.exs=:*.fs=:*.go=:*.h=:*.hh=:*.hpp=:*.hs=:*.html=:*.java=:*.jl=:*.js=:*.json=:*.lua=:*.md=:*.php=:*.pl=:*.pro=:*.py=:*.rb=:*.rs=:*.scala=:*.ts=:*.vim=:*.cmd=:*.ps1=:*.sh=:*.bash=:*.zsh=:*.fish=:*.tar=:*.tgz=:*.arc=:*.arj=:*.taz=:*.lha=:*.lz4=:*.lzh=:*.lzma=:*.tlz=:*.txz=:*.db=:*.tzo=:*.t7z=:*.zip=:*.z=:*.dz=:*.gz=:*.lrz=:*.lz=:*.lzo=:*.xz=:*.zst=:*.tzst=:*.bz2=:*.bz=:*.tbz=:*.tbz2=:*.tz=:*.deb=:*.rpm=:*.jar=:*.war=:*.ear=:*.sar=:*.rar=:*.alz=:*.ace=:*.zoo=:*.cpio=:*.7z=:*.rz=:*.cab=:*.wim=:*.swm=:*.dwm=:*.esd=:*.jpg=:*.jpeg=:*.mjpg=:*.mjpeg=:*.gif=:*.bmp=:*.pbm=:*.pgm=:*.ppm=:*.tga=:*.xbm=:*.xpm=:*.tif=:*.tiff=:*.png=:*.svg=:*.ico=:*.svgz=:*.mng=:*.pcx=:*.mov=:*.mpg=:*.mpeg=:*.m2v=:*.mkv=:*.webm=:*.ogm=:*.mp4=:*.m4v=:*.mp4v=:*.vob=:*.qt=:*.nuv=:*.wmv=:*.asf=:*.rm=:*.rmvb=:*.flc=:*.avi=:*.fli=:*.flv=:*.gl=:*.dl=:*.xcf=:*.xwd=:*.yuv=:*.cgm=:*.emf=:*.ogv=:*.ogx=:*.aac=:*.au=:*.flac=:*.m4a=:*.mid=:*.midi=:*.mka=:*.mp3=:*.mpc=:*.ogg=:*.ra=:*.wav=:*.oga=:*.opus=:*.spx=:*.xspf=:*.pdf=:*.nix=:*.csv=:*.xlsx=󰈛:*.dll= :*.exe=󰣆 :*.xml=󰗀:*.gitignore=󰊢:*.ini=:*.config=:images=󰉏:
"
