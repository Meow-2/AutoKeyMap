# AutoKeyMap

`AutoKeyMap` 是一套基于 AutoHotkey v2 的个人键盘增强脚本，当前主要覆盖三类能力：

- 输入法切换：用 `RAlt` 在微软拼音中英文模式之间切换，并为部分会占用 `RAlt` 的应用提供兼容策略。
- 常用程序快捷启动：把一组 `Win + 键` 热键映射到任务栏固定位置上的应用。
- 桌面与调试辅助：支持 `Win+Q` 关闭窗口后自动把焦点切到当前桌面的顶层程序，并提供调试面板查看当前窗口与输入法状态。

## 运行环境

- Windows
- AutoHotkey v2.0 或更高版本
- 输入法方案默认按微软拼音设计

如果你使用源码运行，入口文件是 [AutoKeyMap.ahk](./AutoKeyMap.ahk)。  
如果你使用编译后的可执行文件，可以直接运行仓库中的 `AutoKeyMap.exe`。

## 功能概览

### 输入法切换

- `RAlt`：在微软拼音中文模式和英文模式之间切换。
- `Esc`：在 Vim/命令式操作场景下，把当前输入法尽量切回英文模式。
- 对 `wps.exe`、`et.exe`、`wpp.exe`、`excel.exe` 这类可能拦截 `RAlt` 的程序，不直接发 IME 控制消息，而是退回为发送可配置按键。

### 程序启动与窗口操作

- `Win+Enter`：打开任务栏第 3 个程序。
- `Win+C`：打开任务栏第 4 个程序。
- `Win+I`：打开任务栏第 5 个程序。
- `Win+W`：打开任务栏第 6 个程序。
- `Win+O`：打开任务栏第 7 个程序。
- `Win+G`：打开任务栏第 8 个程序。
- `Win+M`：打开任务栏第 9 个程序。
- `Win+P`：直接启动 Postman。
- `Win+Q`：关闭当前窗口，并在需要时把焦点切到当前桌面最上层的正常程序窗口。

### 调试

- `Win+Shift+X`：显示活动窗口信息、当前输入法 Layout ID、当前 IME 模式、`ImeToggleKey` 和 `RAltOccupiedApps` 命中情况。

这个调试窗口是只读文本面板，默认不显示插入光标，但仍然可以选择和复制文本。

## 配置说明

主要配置位于 [Config.ahk](./Config.ahk)：

- `ImeToggleKey`
  用于被特定程序占用 `RAlt` 时的兜底切换键，默认是 `"{Shift}"`。
- `EnglishLayoutId`
  英文键盘布局 ID。
- `ChineseLayoutId`
  微软拼音布局 ID。
- `RAltOccupiedApps`
  需要走兜底切换逻辑的进程名列表。

如果换了电脑或输入法环境，`RAlt` 切换不生效，优先按下面的顺序排查：

1. 运行脚本后按 `Win+Shift+X`。
2. 记录调试面板里的 `IME Layout ID`。
3. 对比 `EnglishLayoutId` / `ChineseLayoutId` 是否与当前机器一致。
4. 如不一致，修改 [Config.ahk](./Config.ahk) 后重新加载脚本。

## 模块结构

当前代码已经按职责拆分为多个模块：

- [AutoKeyMap.ahk](./AutoKeyMap.ahk)：入口文件，只负责 `#Include` 各模块。
- [Config.ahk](./Config.ahk)：集中存放全局配置项。
- [ImeCore.ahk](./ImeCore.ahk)：IME 状态读取、切换和光标位置辅助。
- [AppRules.ahk](./AppRules.ahk)：应用级规则判断，目前负责 `RAlt` 占用应用识别。
- [DebugPanel.ahk](./DebugPanel.ahk)：调试面板显示、隐藏和活动窗口信息输出。
- [WindowManager.ahk](./WindowManager.ahk)：窗口关闭后焦点切换、顶层窗口筛选和 cloaked 窗口判断。
- [Hotkeys.ahk](./Hotkeys.ahk)：热键定义与行为入口。

更详细的模块说明见 [Doc/Modules.md](./Doc/Modules.md)。  
热键与配置索引见 [Doc/Hotkeys.md](./Doc/Hotkeys.md) 和 [Doc/Configuration.md](./Doc/Configuration.md)。

## 使用方式

### 源码运行

1. 安装 AutoHotkey v2。
2. 双击 [AutoKeyMap.ahk](./AutoKeyMap.ahk) 运行脚本。
3. 如果修改了任意 `.ahk` 文件，重新加载脚本使配置生效。

### 编译文件运行

1. 直接运行 `AutoKeyMap.exe`。
2. 如果你修改的是源码，需重新编译后 exe 才会同步更新。

## 任务栏映射前提

`Win+Enter`、`Win+C`、`Win+I`、`Win+W`、`Win+O`、`Win+G`、`Win+M` 这些热键依赖 Windows 任务栏固定顺序。  
如果任务栏顺序与你的个人布局不一致，实际打开的程序也会不同。

## 已知限制

- 这套输入法切换逻辑是按“微软拼音 + Windows”设计的，换成其他输入法未必兼容。
- 某些程序会深度拦截按键或自己管理输入法状态，兼容性不能保证完全一致。
- `Win+Q` 的焦点回退逻辑会尽量选择当前桌面上最上层的正常窗口，但遇到程序自带退出确认框时，会优先保留当前已获得焦点的窗口。

## 后续维护建议

- 新增热键时，优先只改 [Hotkeys.ahk](./Hotkeys.ahk)。
- 新增配置项时，优先放到 [Config.ahk](./Config.ahk)。
- 新增窗口筛选或激活策略时，优先放到 [WindowManager.ahk](./WindowManager.ahk)。
- 新增调试展示时，优先放到 [DebugPanel.ahk](./DebugPanel.ahk)。
