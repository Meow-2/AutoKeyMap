# 配置说明

当前脚本的可调参数主要位于 `Config.ahk`。这一页只解释“改什么会影响什么”。

## `ImeToggleKey`

默认值：

```ahk
global ImeToggleKey := "{Shift}"
```

作用：
- 当某些程序占用 `RAlt`，导致脚本无法稳定直接切换 IME 时，退回为发送这个按键。

可选示例：

```ahk
global ImeToggleKey := "{Shift}"
global ImeToggleKey := "{Ctrl}"
global ImeToggleKey := "^ "
```

适用场景：
- 某些机器把切换中英文绑定在 `Shift`。
- 某些输入法配置成 `Ctrl` 或 `Ctrl+Space`。

## `EnglishLayoutId`

默认值：

```ahk
global EnglishLayoutId := 67699721
```

作用：
- 指定英文键盘布局 ID。

什么时候要改：
- 换电脑后 `RAlt`/`Esc` 逻辑失效。
- `Win+Shift+X` 显示出来的实际 Layout ID 与这里不一致。

## `ChineseLayoutId`

默认值：

```ahk
global ChineseLayoutId := 134481924
```

作用：
- 指定微软拼音布局 ID。

什么时候要改：
- 当前机器的微软拼音布局 ID 与默认值不一致。

## `RAltOccupiedApps`

默认值：

```ahk
global RAltOccupiedApps := ["wps.exe", "et.exe", "wpp.exe", "excel.exe"]
```

作用：
- 这些程序命中后，`RAlt` 不再直接走 IME 消息切换，而是发送 `ImeToggleKey`。

什么时候要改：
- 你发现某个程序里 `RAlt` 被软件自己拦截。
- 你想给更多 Office 类或富文本程序加兼容规则。

## `DebugInfoGui` 与 `DebugInfoEdit`

默认值：

```ahk
global DebugInfoGui := 0
global DebugInfoEdit := 0
```

作用：
- 这两个是调试窗口的全局对象缓存。
- 一般不需要手工调整。

## 推荐排查流程

当输入法切换行为异常时，建议按下面顺序排查：

1. 按 `Win+Shift+X` 打开调试窗口。
2. 查看当前 `IME Layout ID`。
3. 对比 `EnglishLayoutId` / `ChineseLayoutId` 是否匹配。
4. 如果只在个别程序里异常，判断是否需要把进程名加入 `RAltOccupiedApps`。
5. 如果命中占用规则后还是不好用，尝试更换 `ImeToggleKey`。
