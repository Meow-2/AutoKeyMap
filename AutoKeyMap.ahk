#Requires AutoHotkey v2.0
#SingleInstance Force
;#UseHook

; WPS这类RAlt被占用的编辑器里，直接走 IME 消息切换不稳定，
; 因此在这些进程中会退回为“发送一个按键”来触发输入法切换。
; 可选示例：
;   global ImeToggleKey := "{Shift}"  ; 发送 Shift
;   global ImeToggleKey := "{Ctrl}"   ; 发送 Ctrl
;   global ImeToggleKey := "^ "       ; 发送 Ctrl+Space
; 输入法布局 ID 也抽成全局配置，便于换机器后直接调整。
; 如果换机器后不生效，可先用 Win+Shift+X 查看当前窗口的 Layout ID，
; RAltOccupiedApps 用于配置“RAlt 被应用占用”的进程名列表。
global ImeToggleKey := "{Shift}"
global EnglishLayoutId := 67699721
global ChineseLayoutId := 134481924
global RAltOccupiedApps := ["wps.exe", "et.exe", "wpp.exe", "excel.exe"]
global DebugInfoGui := 0
global DebugInfoEdit := 0

; 将对应的软件固定到任务栏对应位置，win+1为微信，win+2为企业微信
; --- Win + 键 映射（并屏蔽系统行为） ---
#q::Send("!{F4}")     ; Win+Q → Alt+F4 关闭活动窗口
#Enter::Send("#{3}")  ; Win+Enter → Win+3 打开终端
#c::Send("#{4}")      ; Win+C → Win+4 打开浏览器
#i::Send("#{5}")      ; Win+I → Win+5 打开IDEA
#w::Send("#{6}")      ; Win+W → Win+6 打开WebStorm
#o::Send("#{7}")      ; Win+O → Win+7 打开Zed
#g::Send("#{8}")      ; Win+G → Win+8 打开Dbeaver
#m::Send("#{9}")      ; Win+M → Win+9 打开QQMusic

; --- Win + P → 打开Postman程序 ---
#p::Run(EnvGet("USERPROFILE") "\scoop\apps\postman\current\app\Postman.exe") ; 打开Postman

; IME状态读取和切换，支持微软拼音中英文状态的切换
; 输入法智能切换中英文，用autohotkey如何实现？ - 龍林的回答 - 知乎 https://www.zhihu.com/question/41446565/answer/43058791607
; AHK的CaretGetPos不够强，作者使用了更强的版本
CaretGetPosEx(&x?, &y?, &w?, &h?) { ; Source: https://www.autoahk.com/archives/44158
    x := y := w := h := 0 ; pre-conditioning
    static iUIAutomation := 0, hOleacc := 0, IID_IAccessible, guiThreadInfo, _ := init()
    if !iUIAutomation || ComCall(8, iUIAutomation, "ptr*", eleFocus := ComValue(13, 0), "int") || !eleFocus.Ptr
        goto useAccLocation
    if !ComCall(16, eleFocus, "int", 10002, "ptr*", valuePattern := ComValue(13, 0), "int") && valuePattern.Ptr
        if !ComCall(5, valuePattern, "int*", &isReadOnly := 0) && isReadOnly
            return 0
    useAccLocation:
    ; use IAccessible::accLocation
    hwndFocus := DllCall("GetGUIThreadInfo", "uint", DllCall("GetWindowThreadProcessId", "ptr", WinExist("A"), "ptr", 0, "uint"), "ptr", guiThreadInfo) && NumGet(guiThreadInfo, A_PtrSize == 8 ? 16 : 12, "ptr") || WinExist()
    if hOleacc && !DllCall("Oleacc\AccessibleObjectFromWindow", "ptr", hwndFocus, "uint", 0xFFFFFFF8, "ptr", IID_IAccessible, "ptr*", accCaret := ComValue(13, 0), "int") && accCaret.Ptr {
        NumPut("ushort", 3, varChild := Buffer(24, 0))
        if !ComCall(22, accCaret, "int*", &x := 0, "int*", &y := 0, "int*", &w := 0, "int*", &h := 0, "ptr", varChild, "int")
            return hwndFocus
    }
    if iUIAutomation && eleFocus {
        ; use IUIAutomationTextPattern2::GetCaretRange
        if ComCall(16, eleFocus, "int", 10024, "ptr*", textPattern2 := ComValue(13, 0), "int") || !textPattern2.Ptr
            goto useGetSelection
        if ComCall(10, textPattern2, "int*", &isActive := 0, "ptr*", caretTextRange := ComValue(13, 0), "int") || !caretTextRange.Ptr || !isActive
            goto useGetSelection
        if !ComCall(10, caretTextRange, "ptr*", &rects := 0, "int") && rects && (rects := ComValue(0x2005, rects, 1)).MaxIndex() >= 3 {
            x := rects[0], y := rects[1], w := rects[2], h := rects[3]
            return hwndFocus
        }
        useGetSelection:
        ; use IUIAutomationTextPattern::GetSelection
        if textPattern2.Ptr
            textPattern := textPattern2
        else if ComCall(16, eleFocus, "int", 10014, "ptr*", textPattern := ComValue(13, 0), "int") || !textPattern.Ptr
            goto useGUITHREADINFO
        if ComCall(5, textPattern, "ptr*", selectionRangeArray := ComValue(13, 0), "int") || !selectionRangeArray.Ptr
            goto useGUITHREADINFO
        if ComCall(3, selectionRangeArray, "int*", &length := 0, "int") || length <= 0
            goto useGUITHREADINFO
        if ComCall(4, selectionRangeArray, "int", 0, "ptr*", selectionRange := ComValue(13, 0), "int") || !selectionRange.Ptr
            goto useGUITHREADINFO
        if ComCall(10, selectionRange, "ptr*", &rects := 0, "int") || !rects
            goto useGUITHREADINFO
        rects := ComValue(0x2005, rects, 1)
        if rects.MaxIndex() < 3 {
            if ComCall(6, selectionRange, "int", 0, "int") || ComCall(10, selectionRange, "ptr*", &rects := 0, "int") || !rects
                goto useGUITHREADINFO
            rects := ComValue(0x2005, rects, 1)
            if rects.MaxIndex() < 3
                goto useGUITHREADINFO
        }
        x := rects[0], y := rects[1], w := rects[2], h := rects[3]
        return hwndFocus
    }
    useGUITHREADINFO:
    if hwndCaret := NumGet(guiThreadInfo, A_PtrSize == 8 ? 48 : 28, "ptr") {
        if DllCall("GetWindowRect", "ptr", hwndCaret, "ptr", clientRect := Buffer(16)) {
            w := NumGet(guiThreadInfo, 64, "int") - NumGet(guiThreadInfo, 56, "int")
            h := NumGet(guiThreadInfo, 68, "int") - NumGet(guiThreadInfo, 60, "int")
            DllCall("ClientToScreen", "ptr", hwndCaret, "ptr", guiThreadInfo.Ptr + 56)
            x := NumGet(guiThreadInfo, 56, "int")
            y := NumGet(guiThreadInfo, 60, "int")
            return hwndCaret
        }
    }
    return 0
    static init() {
        try
            iUIAutomation := ComObject("{E22AD333-B25F-460C-83D0-0581107395C9}", "{30CBE57D-D9D0-452A-AB13-7AC5AC4825EE}")
        hOleacc := DllCall("LoadLibraryW", "str", "Oleacc.dll", "ptr")
        NumPut("int64", 0x11CF3C3D618736E0, "int64", 0x719B3800AA000C81, IID_IAccessible := Buffer(16))
        guiThreadInfo := Buffer(A_PtrSize == 8 ? 72 : 48), NumPut("uint", guiThreadInfo.Size, guiThreadInfo)
        return 0
    }
}

Class IME {
    static get := (*) => DllCall("GetKeyboardLayout", "UInt",
        DllCall("GetWindowThreadProcessId", "UInt", WinGetID("A"), "UInt", 0))

    static keyboardLayoutID := Map(
        "en", EnglishLayoutId, ; 美式键盘布局ID
        "ch", ChineseLayoutId, ; 微软拼音输入法布局ID
        ; more language
    )

    ; IME.set("en") 切换到美式键盘
    ; IME.set("ch", False) 切换到微软拼音英文模式
    ; IME.set("ch", True) 切换到微软拼音中文模式
    static set(lan := "en", not_to_en := False, show := True, win := "A") {
        if NOT (win_id := WinExist(win))
            return
        ; 显示当前中英文状态弹窗函数
        ; SetTimer marker, show ? -50 : 0
        hWnd := DllCall("imm32.dll\ImmGetDefaultIMEWnd", "UInt", win_id)
        PostMessage(0x50, , IME.keyboardLayoutID[lan], hWnd)
        ; 0x50: WM_INPUTLANGCHANGEREQUEST
        if lan == "en"
            return
        Sleep(50), SendMessage(0x283, 0x2, not_to_en, hWnd)
        ; 0x283: WM_IME_CONTROL, 0x2: IMC_SETOPENSTATUS，lParam: 0-en | 1-!en
        ; 显示当前中英文状态弹窗函数
        marker() {
            CaretGetPosEx(&x, &y), x := IsSet(x) ? x : 0, y := IsSet(y) ? y : 0
            ToolTip (lan == "en" ? "EN" : (not_to_en ? lan : "en")), x+10, y+10, 3
            SetTimer () => ToolTip(,,,3), -500
        }
    }

    ; 微软拼音英文模式返回1，中文模式返回0，美式键盘返回-1
    static isEnglishMode() {
        DetectHiddenWindows True
        is_en := NOT SendMessage(
            0x283, ; Message: WM_IME_CONTROL
            0x001, ; wParam: IMC_GETCONVERSIONMODE
            0, ; lParam: (NoArgs)
            , ; Control: (Window), Retrieves the default window handle.
            "ahk_id " . DllCall("imm32\ImmGetDefaultIMEWnd", "UInt", WinGetID("A")))
        DetectHiddenWindows False
        return IME.get() == IME.keyboardLayoutID["en"] ? -1 : is_en
    }
}

isRAltOccupiedApp() {
    try {
        process_name := StrLower(WinGetProcessName("A"))
        for app in RAltOccupiedApps {
            if (process_name = StrLower(app))
                return True
        }
        return False
    }
    catch {
        return False
    }
}

RAlt:: {
    try {
        if isRAltOccupiedApp() {
            ; RAlt 被应用占用时，优先走可配置按键，兼容性比直接发 IME 消息更稳。
            Send(ImeToggleKey)
            return
        }
        ime_status := IME.isEnglishMode()
        ; 如果当前是微软拼音中文模式
        if (ime_status == 0) {
            ; 切换到微软拼音英文模式
            IME.set("ch", False)
        }else{
            ; 切换到微软拼音中文模式
            IME.set("ch", True)
        }
    }
    catch {
        return
    }
}

; 用于 VIM IM 自动切换
; ~ 前缀表示热键执行时 **不阻止原始按键功能**，Esc 会自动触发
~Esc:: {
    try{
        ime_status := IME.isEnglishMode()
        ; 如果当前是微软拼音中文模式
        if (ime_status == 0) {
            ; 切换到微软拼音英文模式
            IME.set("ch", False)
        }
    }
    catch {
        return
    }
}

hideDebugInfoGui(*) {
    global DebugInfoGui
    if IsObject(DebugInfoGui) {
        DebugInfoGui.Hide()
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
        DebugInfoGui.OnEvent("Close", hideDebugInfoGui)
        DebugInfoGui.OnEvent("Escape", hideDebugInfoGui)
    }

    DebugInfoEdit.Value := text
    ; timeout/whichToolTip 参数保留，仅为兼容现有调用点；当前策略是手动关闭。
    DebugInfoGui.Show("AutoSize x10 y10")
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

; 调试说明：
; 1. Win+Shift+X 会显示当前活动窗口信息、当前 Layout ID、配置中的 EN/CH Layout ID、
;    当前 IME Mode，以及 RAlt 占用分支会发送的 ImeToggleKey。
; 2. 如果你只想快速看当前活动窗口的输入法布局 ID，可以临时取消下面 F1 热键的注释。
; 3. 当 Win+Shift+X 里的 Layout ID 与 EnglishLayoutId / ChineseLayoutId 不一致时，
;    说明这台机器的输入法布局 ID 和当前脚本配置不一致，需要更新全局变量。
+#x:: {
    showActiveWindowInfo()
}
