# 模块说明

本文档按当前仓库的实际拆分方式，说明每个模块的职责边界、核心函数和推荐修改位置。

## 入口层

### `AutoKeyMap.ahk`

作用：
- 作为脚本入口。
- 负责声明 `#Requires AutoHotkey v2.0` 和 `#SingleInstance Force`。
- 用 `#Include` 按顺序引入各模块。

当前 include 顺序：
1. `Config.ahk`
2. `ImeCore.ahk`
3. `AppRules.ahk`
4. `DebugPanel.ahk`
5. `WindowManager.ahk`
6. `Hotkeys.ahk`

维护建议：
- 这里只放入口声明和模块引入。
- 不建议在这里继续堆放业务逻辑。

## 配置层

### `Config.ahk`

作用：
- 集中定义全局配置。
- 给其他模块提供共享参数。

当前配置项：
- `ImeToggleKey`
  在特定应用占用 `RAlt` 时发送的兜底按键。
- `EnglishLayoutId`
  英文布局 ID。
- `ChineseLayoutId`
  微软拼音布局 ID。
- `RAltOccupiedApps`
  需要走兜底切换逻辑的进程名列表。
- `DebugInfoGui`
  调试面板 GUI 对象缓存。
- `DebugInfoEdit`
  调试面板文本控件缓存。

维护建议：
- 所有“机器相关”“环境相关”“个人偏好相关”的值都优先放这里。
- 新增配置后，README 和 `Doc/Configuration.md` 需要同步更新。

## 输入法层

### `ImeCore.ahk`

作用：
- 提供输入法状态读取与切换的底层能力。
- 为调试面板和热键逻辑提供统一的 IME 接口。

核心内容：
- `CaretGetPosEx(&x?, &y?, &w?, &h?)`
  读取插入点位置。当前代码保留了这部分能力，主要用于输入法提示的扩展场景。
- `class IME`
  输入法操作的核心类。

`IME` 类的主要方法：
- `IME.get()`
  获取当前窗口线程的输入法布局 ID。
- `IME.set(lan := "en", not_to_en := False, show := True, win := "A")`
  切换输入法布局或微软拼音中英文模式。
- `IME.isEnglishMode()`
  判断当前是否处于英文模式。
  返回值约定：
  - `1`：微软拼音英文模式
  - `0`：微软拼音中文模式
  - `-1`：当前是美式键盘布局

维护建议：
- 输入法相关的底层 `DllCall`、`SendMessage`、`PostMessage` 都应放在这里。
- 热键文件不应直接堆叠底层输入法调用细节。

## 应用规则层

### `AppRules.ahk`

作用：
- 负责根据当前活动进程决定是否命中特定应用规则。

当前函数：
- `isRAltOccupiedApp()`
  判断活动窗口进程是否在 `RAltOccupiedApps` 列表中。

使用场景：
- `Hotkeys.ahk` 中 `RAlt` 热键会先调用这个函数。
- 如果命中，则发送 `ImeToggleKey`，而不是直接走 IME 控制消息。

维护建议：
- 如果以后要加“某些程序下禁用某热键”“某些程序下特殊切换逻辑”，适合继续放在这里。

## 调试展示层

### `DebugPanel.ahk`

作用：
- 提供调试窗口的创建、显示、隐藏和内容刷新。
- 输出当前活动窗口与输入法状态，便于调试布局 ID 和规则命中情况。

核心函数：
- `hideDebugInfoGui(*)`
  隐藏调试窗口。
- `hideDebugEditCaret(*)`
  隐藏调试文本框的插入光标。
- `resetDebugEditView(*)`
  清除默认选区并隐藏光标。
- `showDebugToolTip(text, timeout := 1500, whichToolTip := 4)`
  显示调试窗口并写入文本。
- `showActiveWindowInfo()`
  输出活动窗口的进程名、标题、类名、HWND、Layout ID、IME 模式和相关配置。

实现特点：
- 调试文本框是只读的。
- 默认不显示插入光标。
- 用户仍然可以选择和复制文本。

维护建议：
- 调试输出统一从这里扩展，不要把调试 GUI 代码散落到其他模块。

## 窗口管理层

### `WindowManager.ahk`

作用：
- 处理窗口关闭后的焦点切换。
- 提供“可被当作正常桌面程序窗口”的筛选逻辑。

核心函数：
- `activateTopWindowAfterClose(closingHwnd, waitMs := 800)`
  等待目标窗口关闭后，尝试把焦点激活到当前桌面最上层的正常程序窗口。
- `isDesktopTopLevelAppWindow(hwnd, excludedHwnd := 0)`
  判断窗口是否适合作为焦点切换目标。
- `isWindowCloaked(hwnd)`
  判断窗口是否被 DWM 标记为 cloaked。

筛选逻辑当前会排除：
- 被关闭的原窗口
- 不可见窗口
- 最小化窗口
- `ToolWindow`
- `NoActivate`
- 任务栏、桌面壳窗口
- cloaked 窗口

维护建议：
- 任何“切换窗口焦点”“枚举顶层窗口”“窗口过滤规则”的改动，都优先集中在这里。

## 热键层

### `Hotkeys.ahk`

作用：
- 定义用户直接触发的热键。
- 作为热键行为的入口层，调用其他模块能力。

当前热键分组：
- 窗口关闭与程序启动
- 输入法切换
- Vim IM 自动切换
- 调试面板

设计原则：
- `Hotkeys.ahk` 应尽量只保留热键定义和少量流程编排。
- 复杂逻辑尽量委托给 `ImeCore.ahk`、`AppRules.ahk`、`WindowManager.ahk`、`DebugPanel.ahk`。

## 推荐修改路径

如果你准备改动代码，建议按下面的职责边界落位：

- 改全局参数：`Config.ahk`
- 改输入法底层行为：`ImeCore.ahk`
- 改应用特例规则：`AppRules.ahk`
- 改调试窗口：`DebugPanel.ahk`
- 改关窗后焦点策略：`WindowManager.ahk`
- 改具体按键映射：`Hotkeys.ahk`
