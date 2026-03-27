; IME状态读取和切换，支持微软拼音中英文状态的切换
; 输入法智能切换中英文，用autohotkey如何实现？ - 龍林的回答 - 知乎
; https://www.zhihu.com/question/41446565/answer/43058791607
; AHK的CaretGetPos不够强，作者使用了更强的版本
CaretGetPosEx(&x?, &y?, &w?, &h?) { ; Source: https://www.autoahk.com/archives/44158
    x := y := w := h := 0
    static iUIAutomation := 0, hOleacc := 0, IID_IAccessible, guiThreadInfo, _ := init()
    if !iUIAutomation || ComCall(8, iUIAutomation, "ptr*", eleFocus := ComValue(13, 0), "int") || !eleFocus.Ptr
        goto useAccLocation
    if !ComCall(16, eleFocus, "int", 10002, "ptr*", valuePattern := ComValue(13, 0), "int") && valuePattern.Ptr
        if !ComCall(5, valuePattern, "int*", &isReadOnly := 0) && isReadOnly
            return 0
    useAccLocation:
    hwndFocus := DllCall("GetGUIThreadInfo", "uint", DllCall("GetWindowThreadProcessId", "ptr", WinExist("A"), "ptr", 0, "uint"), "ptr", guiThreadInfo) && NumGet(guiThreadInfo, A_PtrSize == 8 ? 16 : 12, "ptr") || WinExist()
    if hOleacc && !DllCall("Oleacc\AccessibleObjectFromWindow", "ptr", hwndFocus, "uint", 0xFFFFFFF8, "ptr", IID_IAccessible, "ptr*", accCaret := ComValue(13, 0), "int") && accCaret.Ptr {
        NumPut("ushort", 3, varChild := Buffer(24, 0))
        if !ComCall(22, accCaret, "int*", &x := 0, "int*", &y := 0, "int*", &w := 0, "int*", &h := 0, "ptr", varChild, "int")
            return hwndFocus
    }
    if iUIAutomation && eleFocus {
        if ComCall(16, eleFocus, "int", 10024, "ptr*", textPattern2 := ComValue(13, 0), "int") || !textPattern2.Ptr
            goto useGetSelection
        if ComCall(10, textPattern2, "int*", &isActive := 0, "ptr*", caretTextRange := ComValue(13, 0), "int") || !caretTextRange.Ptr || !isActive
            goto useGetSelection
        if !ComCall(10, caretTextRange, "ptr*", &rects := 0, "int") && rects && (rects := ComValue(0x2005, rects, 1)).MaxIndex() >= 3 {
            x := rects[0], y := rects[1], w := rects[2], h := rects[3]
            return hwndFocus
        }
        useGetSelection:
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

class IME {
    static get := (*) => DllCall("GetKeyboardLayout", "UInt",
        DllCall("GetWindowThreadProcessId", "UInt", WinGetID("A"), "UInt", 0))

    static keyboardLayoutID := Map(
        "en", EnglishLayoutId,
        "ch", ChineseLayoutId
    )

    ; IME.set("en") 切换到美式键盘
    ; IME.set("ch", False) 切换到微软拼音英文模式
    ; IME.set("ch", True) 切换到微软拼音中文模式
    static set(lan := "en", not_to_en := False, show := True, win := "A") {
        if NOT (win_id := WinExist(win))
            return
        hWnd := DllCall("imm32.dll\ImmGetDefaultIMEWnd", "UInt", win_id)
        PostMessage(0x50, , IME.keyboardLayoutID[lan], hWnd)
        if lan == "en"
            return
        Sleep(50), SendMessage(0x283, 0x2, not_to_en, hWnd)
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
            0x283,
            0x001,
            0,
            ,
            "ahk_id " . DllCall("imm32\ImmGetDefaultIMEWnd", "UInt", WinGetID("A")))
        DetectHiddenWindows False
        return IME.get() == IME.keyboardLayoutID["en"] ? -1 : is_en
    }
}
