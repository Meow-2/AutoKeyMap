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
