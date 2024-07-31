Invoke-Expression (&starship init powershell)
Import-Module Terminal-Icons
Import-Module PSReadLine
Set-PSReadLineKeyHandler -Key ~ -Function ClearScreen
Set-PSReadLineKeyHandler -Key Tab -Function Complete
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -BellStyle None
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'
Add-Type -AssemblyName Microsoft.VisualBasic


# Приписки в конце: f(files), d(directory), a(all-items), h(hidden), irr(irrevocably)
# Приписка h(hidden) работает так, что если указан данный параметр, то данные файлы/директории наоборот исключаются (например, из списка перемещаемых файлов)


Set-Alias -Name tt -Value tree
Set-Alias -Name g -Value git
Set-Alias -Name p -Value python
Set-Alias -Name x -Value cls
Set-Alias -Name m -Value micro
Set-Alias -Name n -Value nano

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
            $fullPath = Resolve-Path $item -ErrorAction SilentlyContinue
            if ($fullPath -and (Test-Path $fullPath)) {
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
                }
                else {
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
            } else {
                Write-Host "Файл не найден: $item" -ForegroundColor Red
            }
        }
    }
}
Set-Alias -Name obs -Value Open-Obsidian

function d { Set-Location D:\ }
function dev { Set-Location D:\GolangProject }
function devl { Set-Location D:\GolangProject\GoLearning }
function rrad ($command) { Remove-Item $command -Force -Recurse }
function ll { Get-ChildItem -fo }

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
Set-Alias -Name dow -Value Open-Downloads

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
        Write-Host "Копирование выполнено успешно в '$finalDestination'" -ForegroundColor Green
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
        Write-Host "Невозможно удалить корневую директорию."
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

# Перместить все файлы (-hidden)
function Move-AllFiles {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Destination
    )
    if (-not (Test-Path -Path $Destination -PathType Container)) {
        New-Item -Path $Destination -ItemType Directory -Force | Out-Null
        Write-Host "Создана папка назначения: $Destination" -ForegroundColor Yellow
    }
    $fileCount = (Get-ChildItem -File).Count
    Get-ChildItem -File | Move-Item -Destination $Destination -ErrorAction SilentlyContinue
    $movedCount = $fileCount - (Get-ChildItem -File).Count
    if ($movedCount -lt $fileCount) {
        Write-Host "Некоторые файлы не удалось переместить. Проверьте права доступа или убедитесь, что файлы не используются другими процессами" -ForegroundColor Yellow
        Write-Host "Перемещено файлов: $movedCount из $fileCount" -ForegroundColor Green
    }
}
Set-Alias -Name mvfh -Value Move-AllFiles

# Переместить все файлы (+hidden)
function Move-AllFilesIncludingHidden {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Destination
    )
    if (-not (Test-Path -Path $Destination -PathType Container)) {
        New-Item -Path $Destination -ItemType Directory -Force | Out-Null
        Write-Host "Создана папка назначения: $Destination" -ForegroundColor Green
    }
    $fileCount = (Get-ChildItem -File -Force).Count
    Get-ChildItem -File -Force | Move-Item -Destination $Destination -ErrorAction SilentlyContinue
    $movedCount = $fileCount - (Get-ChildItem -File -Force).Count
    if ($movedCount -lt $fileCount) {
        Write-Host "Некоторые файлы не удалось переместить. Проверьте права доступа или убедитесь, что файлы не используются другими процессами" -ForegroundColor Yellow
        Write-Host "Перемещено файлов: $movedCount из $fileCount" -ForegroundColor Green
    }
}
Set-Alias -Name mvf -Value Move-AllFilesIncludingHidden

# Переместить все элементы (-hidden)
function Move-AllItems {
    param (
        [Parameter(Mandatory = $true)]
        [string] $Destination
    )
    if (-not (Test-Path -Path $Destination -PathType Container)) {
        New-Item -Path $Destination -ItemType Directory -Force | Out-Null
        Write-Host "Создана папка назначения: $Destination" -ForegroundColor Green
    }
    $sameNameFolderExists = Test-Path -Path (Join-Path (Get-Location).Path (Split-Path $Destination -Leaf))
    if ($sameNameFolderExists) {
        $itemCount = (Get-ChildItem).Count - 1
    } else {
        $itemCount = (Get-ChildItem).Count
    }
    Get-ChildItem | Where-Object { $_.FullName -ne (Resolve-Path $Destination).Path } | ForEach-Object {
        try {
            Move-Item -Path $_.FullName -Destination $Destination -ErrorAction Stop
        } catch { }
    }
    if ($sameNameFolderExists) {
        $movedCount = $itemCount+1 - (Get-ChildItem).Count
    } else {
        $movedCount = $itemCount - (Get-ChildItem).Count
    }
    if ($movedCount -lt $itemCount) {
        Write-Host "Некоторые элементы не удалось переместить. Проверьте права доступа или убедитесь, что элементы не используются другими процессами" -ForegroundColor Yellow
        Write-Host "Перемещено элементов: $movedCount из $itemCount" -ForegroundColor Green
    }
}
Set-Alias -Name mvah -Value Move-AllItems

# Переместить все элементы (+hidden)
function Move-AllItemsIncludingHidden {
    param (
        [Parameter(Mandatory = $true)]
        [string] $Destination
    )
    if (-not (Test-Path -Path $Destination -PathType Container)) {
        New-Item -Path $Destination -ItemType Directory -Force | Out-Null
        Write-Host "Создана папка назначения: $Destination" -ForegroundColor Green
    }
    $sameNameFolderExists = Test-Path -Path (Join-Path (Get-Location).Path (Split-Path $Destination -Leaf))
    if ($sameNameFolderExists) {
        $itemCount = (Get-ChildItem -Force).Count - 1
    } else {
        $itemCount = (Get-ChildItem -Force).Count
    }
    Get-ChildItem -Force | Where-Object { $_.FullName -ne (Resolve-Path $Destination).Path } | ForEach-Object {
        try {
            Move-Item -Path $_.FullName -Destination $Destination -Force -ErrorAction Stop
        } catch { }
    }
    if ($sameNameFolderExists) {
        $movedCount = $itemCount+1 - (Get-ChildItem -Force).Count
    } else {
        $movedCount = $itemCount - (Get-ChildItem -Force).Count
    }
    if ($movedCount -lt $itemCount) {
        Write-Host "Некоторые элементы не удалось переместить. Проверьте права доступа или убедитесь, что элементы не используются другими процессами" -ForegroundColor Yellow
        Write-Host "Перемещено элементов: $movedCount из $itemCount" -ForegroundColor Green
    }
}
Set-Alias -Name mva -Value Move-AllItemsIncludingHidden

# Переместить все файлы в родительскую директорию (-hidden)
function Move-AllFilesToParent {
    $Destination = (Get-Item ..).FullName
    $fileCount = (Get-ChildItem -File).Count
    Get-ChildItem -File | Move-Item -Destination $Destination -ErrorAction SilentlyContinue
    $movedCount = $fileCount - (Get-ChildItem -File).Count
    if ($movedCount -lt $fileCount) {
        Write-Host "Некоторые файлы не удалось переместить. Проверьте права доступа или убедитесь, что файлы не используются другими процессами" -ForegroundColor Yellow
        Write-Host "Перемещено файлов: $movedCount из $fileCount" -ForegroundColor Green
    }
}
Set-Alias -Name mvfhcc -Value Move-AllFilesToParent

# Переместить все файлы в родительскую директорию (+hidden)
function Move-AllFilesIncludingHiddenToParent {
    $Destination = (Get-It-Force ..).FullName
    $fileCount = (Get-ChildItem -File -Force).Count
    Get-ChildItem -File -Force | Move-Item -Destination $Destination -ErrorAction SilentlyContinue
    $movedCount = $fileCount - (Get-ChildItem -File -Force).Count
    if ($movedCount -lt $fileCount) {
        Write-Host "Некоторые файлы не удалось переместить. Проверьте права доступа или убедитесь, что файлы не используются другими процессами" -ForegroundColor Yellow
        Write-Host "Перемещено файлов (включая скрытые): $movedCount из $fileCount" -ForegroundColor Green
    }
}
Set-Alias -Name mvfcc -Value Move-AllFilesIncludingHiddenToParent

# Перемещение всех элементов в родительскую папку (-hidden)
function Move-AllItemsToParent {
    $Destination = (Get-Item ..).FullName
    $itemCount = (Get-ChildItem).Count
    Get-ChildItem | Where-Object { $_.FullName -ne $PWD.Path -and $_.FullName -ne $Destination } | ForEach-Object {
        try {
            Move-Item -Path $_.FullName -Destination $Destination -ErrorAction Stop
        } catch { }
    }
    $movedCount = $itemCount - (Get-ChildItem).Count
    if ($movedCount -lt $itemCount - 1) {  # Вычитаем 1, так как текущая папка всегда остается
        Write-Host "Некоторые элементы не удалось переместить. Проверьте права доступа или убедитесь, что элементы не используются другими процессами" -ForegroundColor Yellow
        Write-Host "Перемещено элементов: $movedCount из $($itemCount - 1)" -ForegroundColor Green
    }
}
Set-Alias -Name mvahcc -Value Move-AllItemsToParent

# Перемещение всех элементов в родительскую папку (+hidden)
function Move-AllItemsIncludingHiddenToParent {
    $Destination = (Get-Item -Force ..).FullName
    $itemCount = (Get-ChildItem -Force).Count
    Get-ChildItem -Force | Where-Object { $_.FullName -ne $PWD.Path -and $_.FullName -ne $Destination } | ForEach-Object {
        try {
            Move-Item -Path $_.FullName -Destination $Destination -Force -ErrorAction Stop
        } catch { }
    }
    $movedCount = $itemCount - (Get-ChildItem -Force).Count
    if ($movedCount -lt $itemCount - 1) {  # Вычитаем 1, так как текущая папка всегда остается
        Write-Host "Некоторые элементы не удалось переместить. Проверьте права доступа или убедитесь, что элементы не используются другими процессами" -ForegroundColor Yellow
        Write-Host "Перемещено элементов: $movedCount из $($itemCount - 1)" -ForegroundColor Green
    }
}
Set-Alias -Name mvacc -Value Move-AllItemsIncludingHiddenToParent

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

# Удаление всех файлов (RecycleBin) (+hidden)
function Remove-AllFilesToRecycleBin {
    param (
        [string]$Path
    )
    $files = Get-ChildItem -Path $Path -File -Force
    if ($files.Count -eq 0) {
        Write-Host "Нет файлов для удаления" -ForegroundColor Yellow
        return
    }
    foreach ($file in $files) {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
            $file.FullName,
            [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
            [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
        )
    }
}
Set-Alias -Name rmf -Value Remove-AllFilesToRecycleBin

# Удаление всех элементов (RecycleBin) (+hidden)
function Remove-AllItemsToRecycleBin {
    param (
        [string]$Path
    )
    $items = Get-ChildItem -Path $Path -Force
    if ($items.Count -eq 0) {
        Write-Host "Нет элементов для удаления" -ForegroundColor Yellow
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
Set-Alias -Name rma -Value Remove-AllItemsToRecycleBin

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

function Close-PowerShell {[System.Environment]::Exit(0)}
Set-Alias -Name close -Value Close-PowerShell

Set-Alias -Name open -Value start
Set-Alias -Name ex -Value explorer

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
