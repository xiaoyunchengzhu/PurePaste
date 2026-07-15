<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0%2B-blue?logo=apple" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-5.0-orange?logo=swift" alt="Swift">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
  <img src="https://img.shields.io/github/stars/xiaoyunchengzhu/ActionSense?style=flat&color=yellow" alt="Stars">
  <a href="https://www.xiaoniubuniu.com/products/action-sense/"><img src="https://img.shields.io/badge/Download-Free-4CAF50?logo=safari" alt="Download"></a>
</p>

<p align="center"><b>中文</b> | <a href="README.md">English</a></p>

<br>

<h1 align="center">ActionSense</h1>

<p align="center">
  <b>macOS 剪贴板自动化引擎</b><br>
  <sub>不是剪贴板管理器。ActionSense 理解你复制了<i>什么</i>，并帮你完成下一步。</sub>
</p>

<p align="center">
  <img src="screenshot/demo.gif" alt="ActionSense 演示" width="640">
</p>

<p align="center">
  <a href="https://www.xiaoniubuniu.com/products/action-sense/">
    <b>🔗 xiaoniubuniu.com/products/action-sense</b>
  </a>
</p>

<br>

---

## 为什么选择 ActionSense？

剪贴板管理器帮你**记住**复制过什么。ActionSense 帮你**完成**复制后要做的事。

| 剪贴板管理器 | ActionSense |
|---|---|
| 存储复制历史 | 识别内容类型 |
| 让你搜索过去的记录 | 直接触发下一步操作 |
| 你仍然要手动做事 | App 替你做 |
| 例：Paste、Maccy、Raycast Clipboard | **ActionSense** |

**解决的是不同问题，很多人两个都用。**

### 关键的那一秒

每次复制内容后，都有一道"手工工序"：

```
复制链接  →  切浏览器  →  粘贴  →  回车         (4 步)
复制颜色  →  开调色板  →  粘贴  →  看色值        (4 步)
复制算式  →  开计算器  →  输入  →  复制结果      (4 步)
```

ActionSense 把它压缩成：

```
复制  →  ⌨️ 回车
```

**从 10 秒到 1 秒。** 每天省几百次切换。

---

## 工作原理

```
   你复制了内容
          │
          ▼
┌─────────────────────┐
│  检测器管道          │  10 个检测器按优先级依次匹配
│  URL? 邮箱? JSON?   │  第一个命中即输出
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│  浮动面板            │  出现在鼠标旁边
│  识别为 URL         │  展示检测结果 + 可选操作
│  → 在浏览器中打开    │  回车或点击即可触发
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│  操作执行器          │  打开浏览器 / 复制色值 / 格式化 JSON...
│  搞定               │  面板自动关闭
└─────────────────────┘
```

**全本地运行。** 剪贴板数据永不离开你的电脑，无云端、无统计、无网络请求。

---

## 谁在用？

### 👨‍💻 开发者

| 你复制 | ActionSense 做的事 |
|---|---|
| GitHub Issue 链接 | → 浏览器直接打开 |
| `{"name":"foo","items":[1,2,3]}` | → 一键格式化或压缩 JSON |
| 设计稿里的 `#FF5733` | → 复制 HEX 或 RGB，粘贴进 CSS |
| 报错堆栈信息 | → 清理格式，直接搜索 |
| GitHub 仓库链接 | → 浏览器打开 或 Terminal 打开 |

### 🎨 设计师

| 你复制 | ActionSense 做的事 |
|---|---|
| Figma 的 `#FF5733` | → 预览颜色 + 复制 HEX / RGB |
| Style Guide 的 `rgb(255, 87, 51)` | → 同上，两种格式都识别 |

### 📊 研究人员 & 写作者

| 你复制 | ActionSense 做的事 |
|---|---|
| Safari 复制带格式的链接 | → 剥离格式，转为 Markdown |
| 论文中的日期 `2024-03-15` | → 添加到日历 |
| 经纬度 `39.9042, 116.4074` | → 苹果地图打开 |
| 网页上的邮箱地址 | → 打开邮件客户端 |

### ⚡ 效率控

ActionSense 常驻菜单栏。开启**纯文本模式**后，每次复制自动剥离格式、清理中英文空格、规整空白——无需任何快捷键。

**PasteFlow 模式** 弹出操作面板，**纯文本模式** 静默清理。按场景切换。

---

## 支持的类型与操作

| 内容类型 | 识别模式 | 可用操作 |
|---|---|---|
| **链接** | `https://...`、`http://...` | 浏览器打开、打开仓库（GitHub/GitLab/Bitbucket） |
| **邮箱** | `user@domain.com` | 写邮件 |
| **电话** | 国内/国际号码 | 拨打电话 |
| **颜色** | `#HEX`、`rgb()`、`rgba()` | 复制 HEX、复制 RGB |
| **数学表达式** | `(35+47)*1.2`、`sqrt(144)` | 计算并复制结果 |
| **JSON** | 合法 JSON 字符串 | 格式化（美化）、压缩 |
| **日期/时间** | ISO 格式、常见日期格式 | 添加到日历 |
| **经纬度** | `lat, lng` 小数格式 | 苹果地图打开 |
| **富文本** | 剪贴板 HTML 数据 | 转为 Markdown、转为纯文本 |

---

## 检测器 → 操作管道

架构为扩展而生。每种内容类型是一个独立的 **检测器**，实现统一协议：

```swift
protocol ContentDetecting {
    var identifier: String { get }   // "url"、"color"、"json"...
    var priority: Int { get }        // 检测顺序
    func detect(_ text: String, htmlData: Data?) -> DetectedContent?
}
```

**注册一个检测器 → 自动加入管道。** 无需修改核心代码，无需改 switch 语句。

```swift
// 添加自定义检测器
struct JiraTicketDetector: ContentDetecting {
    let identifier = "jira"
    let priority = 15

    func detect(_ text: String, htmlData: Data?) -> DetectedContent? {
        // 匹配 PROJ-1234 模式
        let pattern = /[A-Z]{2,10}-\d{1,6}/
        guard text.contains(pattern) else { return nil }
        return .jiraTicket(String(text.trimmingPrefix(pattern)))
    }
}

// 一行注册
DetectorRegistry.shared.register(JiraTicketDetector())
```

**检测器和操作相互独立。** 协议的边界让它们解耦——新增内容类型直接可用。

---

## 路线图

检测器 → 操作的架构让 ActionSense 成为一个**可扩展的自动化平台**，而不是一个静态工具。

| 阶段 | 内容 |
|---|---|
| **已完成 ✅** | 10 个检测器、14 种操作、纯文本模式、意图历史 |
| **近期** | Jira 工单识别、Slack 频道链接、Figma 链接、终端命令 |
| **规划中** | 用户自定义检测器（正则 → 操作映射）、AppleScript/快捷指令集成 |
| **愿景** | `IF 剪贴板匹配 X THEN 执行 Y` —— 人人都能配置的规则引擎 |

最终目标：**你定义规则，ActionSense 执行。** 基础工作流无需编程。开发者可用完整 Swift API。

---

## 安装

### 方式一：下载 DMG

从 **[xiaoniubuniu.com/products/action-sense](https://www.xiaoniubuniu.com/products/action-sense/)** 下载。

打开 DMG → 拖 `ActionSense.app` 到 `Applications` 文件夹。

> **首次打开：** 右键点击 App → **打开**。或者 系统设置 → 隐私与安全性 → 仍要打开。这是未签名应用的一次性 Gatekeeper 绕过步骤。

### 方式二：源码编译

```bash
git clone https://github.com/xiaoyunchengzhu/ActionSense.git
cd ActionSense
open ActionSense.xcodeproj
# Product → Run (⌘R)
```

零依赖安装。纯 Swift + SwiftUI + AppKit。

### 本地构建 DMG

```bash
./scripts/build_dmg.sh
```

DMG 输出到 `release/` 目录。

---

## 技术栈

**SwiftUI · AppKit · MenuBarExtra · NSPasteboard · Combine · SMAppService**

- 菜单栏应用——不占 Dock 空间
- 浮动面板：`.nonactivatingPanel` 窗口层级，跟随鼠标
- 0.5 秒剪贴板轮询（Timer + `NSPasteboard.changeCount`）
- 手写递归下降数学解析器（避免 `NSExpression` 的安全风险）
- 基于协议的检测器注册表 + 依赖注入
- 5 种语言：中文、英文、日文、法文、德文

---

## 项目结构

```
ActionSense/
├── ActionSenseApp.swift          # MenuBarExtra 入口
├── ActionSenseViewModel.swift    # 状态协调（支持依赖注入）
├── ClipboardMonitor.swift        # NSPasteboard 轮询
├── DetectorProtocol.swift        # ContentDetecting 协议 + Registry
├── Detectors/
│   ├── BasicDetectors.swift      # URL / Email / Phone
│   ├── ColorDetector.swift       # Hex / RGB / RGBA 解析
│   ├── MathDetector.swift        # 递归下降解析器
│   └── TextDetectors.swift       # 日期 / JSON / 经纬度 / HTML
├── ContentDetector.swift         # DetectedContent + PasteFlowAction 枚举
├── ActionExecutor.swift          # 操作分发
├── FloatingPanelView.swift       # SwiftUI 浮动面板
├── FloatingPanelController.swift # NSWindow 管理
├── History/                      # 意图历史 + 搜索
├── Localization.swift            # L10n + String(localized:)
└── Localizable.xcstrings         # String Catalog (en + zh-Hans)
```

---

## 参与贡献

最简单的贡献方式是写一个新的检测器。选一种内容类型，实现协议，提交 PR。

参考 [DetectorProtocol.swift](ActionSense/DetectorProtocol.swift) 了解接口定义，参考现有检测器了解实现方式。

---

## 许可证

MIT — 详见 [LICENSE](LICENSE)。

<p align="center">
  <sub>Built with ❤️ by <a href="https://github.com/xiaoyunchengzhu">xiaoyunchengzhu</a></sub>
</p>
