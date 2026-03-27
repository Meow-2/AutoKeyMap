activateTopWindowAfterClose(closingHwnd, waitMs := 800) {
    deadline := A_TickCount + waitMs
    while (A_TickCount < deadline) {
        if !WinExist("ahk_id " closingHwnd) {
            break
        }
        Sleep(30)
    }

    activeHwnd := 0
    try {
        activeHwnd := WinGetID("A")
    }
    if activeHwnd && (activeHwnd != closingHwnd) && isDesktopTopLevelAppWindow(activeHwnd) {
        return True
    }

    for hwnd in WinGetList() {
        if !isDesktopTopLevelAppWindow(hwnd, closingHwnd) {
            continue
        }
        try {
            WinActivate("ahk_id " hwnd)
            if WinWaitActive("ahk_id " hwnd, , 0.5) {
                return True
            }
        }
    }
    return False
}

isDesktopTopLevelAppWindow(hwnd, excludedHwnd := 0) {
    if (hwnd = excludedHwnd) {
        return False
    }
    if !WinExist("ahk_id " hwnd) {
        return False
    }
    if !DllCall("IsWindowVisible", "ptr", hwnd) {
        return False
    }
    if (WinGetMinMax("ahk_id " hwnd) = -1) {
        return False
    }

    exStyle := WinGetExStyle("ahk_id " hwnd)
    if (exStyle & 0x80) || (exStyle & 0x08000000) {
        return False
    }

    className := WinGetClass("ahk_id " hwnd)
    if className ~= "^(Shell_TrayWnd|Progman|WorkerW)$" {
        return False
    }

    return !isWindowCloaked(hwnd)
}

isWindowCloaked(hwnd) {
    cloaked := 0
    if DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 14, "int*", &cloaked, "uint", 4) != 0 {
        return False
    }
    return cloaked != 0
}
