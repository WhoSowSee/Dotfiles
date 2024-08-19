#NoTrayIcon

#o::
{
    Run("D:\Obsidian\obsidian.exe")
    if WinWait("ahk_exe obsidian.exe", , 10) {
        WinActivate
    } else {
        MsgBox("Obsidian не удалось открыть")
    }
}
