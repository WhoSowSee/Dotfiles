#NoTrayIcon

^!+vkDB:: ; vkDB соответствует клавише "[" в русской раскладке
{
    Run("C:\Program Files\WezTerm\wezterm-gui.exe")
    if WinWait("ahk_exe wezterm-gui.exe", , 10) {
        WinActivate
    } else {
        MsgBox("WezTerm не удалось открыть")
    }
}
