#NoTrayIcon

#c::
{
    Run("C:\Users\whosowsee\AppData\Local\Programs\Microsoft VS Code\Code.exe")
    if WinWait("ahk_exe Code.exe", , 10) {
        WinActivate
    } else {
        MsgBox("VsCode не удалось открыть")
    }
}
