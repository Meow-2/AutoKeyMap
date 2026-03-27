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
#p::Run(EnvGet("USERPROFILE") "\scoop\apps\postman\current\app\Postman.exe")

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
        } else {
            ; 切换到微软拼音中文模式
            IME.set("ch", True)
        }
    }
    catch {
        return
    }
}

; 用于 VIM IM 自动切换
; ~ 前缀表示热键执行时不阻止原始按键功能，Esc 会自动触发
~Esc:: {
    try {
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

; 调试说明：
; 1. Win+Shift+X 会显示当前活动窗口信息、当前 Layout ID、配置中的 EN/CH Layout ID、
;    当前 IME Mode，以及 RAlt 占用分支会发送的 ImeToggleKey。
; 2. 如果 Win+Shift+X 里的 Layout ID 与 EnglishLayoutId / ChineseLayoutId 不一致，
;    说明这台机器的输入法布局 ID 和当前脚本配置不一致，需要更新全局变量。
+#x:: {
    showActiveWindowInfo()
}
