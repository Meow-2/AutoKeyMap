hideDebugInfoGui(*) {
    global DebugInfoGui
    if IsObject(DebugInfoGui) {
        DebugInfoGui.Hide()
    }
}

hideDebugEditCaret(*) {
    global DebugInfoEdit
    if IsObject(DebugInfoEdit) {
        DllCall("HideCaret", "ptr", DebugInfoEdit.Hwnd)
    }
}

resetDebugEditView(*) {
    global DebugInfoEdit
    if IsObject(DebugInfoEdit) {
        DllCall("SendMessage", "ptr", DebugInfoEdit.Hwnd, "uint", 0x00B1, "ptr", 0, "ptr", 0)
        hideDebugEditCaret()
    }
}

showDebugToolTip(text, timeout := 1500, whichToolTip := 4) {
    global DebugInfoGui, DebugInfoEdit

    if !IsObject(DebugInfoGui) {
        DebugInfoGui := Gui("+AlwaysOnTop +ToolWindow +Border", "AKM Debug")
        DebugInfoGui.MarginX := 10
        DebugInfoGui.MarginY := 10
        DebugInfoGui.BackColor := "F7F7F7"
        DebugInfoGui.SetFont("s10", "Consolas")

        DebugInfoEdit := DebugInfoGui.AddEdit("xm ym w620 r12 ReadOnly -Wrap")
        DebugInfoEdit.OnEvent("Focus", hideDebugEditCaret)
        DebugInfoGui.OnEvent("Close", hideDebugInfoGui)
        DebugInfoGui.OnEvent("Escape", hideDebugInfoGui)
    }

    DebugInfoEdit.Value := text
    ; timeout/whichToolTip 参数保留，仅为兼容现有调用点；当前策略是手动关闭。
    DebugInfoGui.Show("AutoSize x10 y10")
    resetDebugEditView()
}

showActiveWindowInfo() {
    try {
        hwnd := WinGetID("A")
        process_name := WinGetProcessName("ahk_id " hwnd)
        title := WinGetTitle("ahk_id " hwnd)
        class_name := WinGetClass("ahk_id " hwnd)
        layout_id := IME.get()
        ime_mode := IME.isEnglishMode()
        ralt_occupied := isRAltOccupiedApp() ? "In Config List" : "Not In Config List"
        info := "Process: " process_name
            . "`nTitle: " (title != "" ? title : "<untitled>")
            . "`nClass: " class_name
            . "`nHWND: " hwnd
            . "`nIME Layout ID: " layout_id
            . "`nIME Mode(en:1 zh:0): " ime_mode
            . "`nAKM EN ID Config: " EnglishLayoutId
            . "`nAKM CH ID Config: " ChineseLayoutId
            . "`nAKM Toggle Key Config: " ImeToggleKey
            . "`nRAlt Occupation List Config: " ralt_occupied
        showDebugToolTip(info, 5000, 5)
    }
    catch Error as err {
        showDebugToolTip("Window info failed: " err.Message, 5000, 5)
    }
}
