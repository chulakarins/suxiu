# 苏绣 AI · Suxiu AI

> 以 SwiftUI 构建的苏绣文化学习与 AI 创作比赛演示应用。当前版本采用完全本地的 Mock 生图流程，不需要 API Key，也不依赖生成服务网络。

[![Platform](https://img.shields.io/badge/platform-iOS%2026%2B-0A84FF)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5-orange)](https://swift.org/)
[![UI](https://img.shields.io/badge/UI-SwiftUI-purple)](https://developer.apple.com/xcode/swiftui/)
[![Mode](https://img.shields.io/badge/AI-Mock%20Offline-2E8B57)](#mock-生图流程)

## 当前版本

这是一个可离线运行、适合比赛现场展示的原型：

- 19 张本地苏绣候选图，按提示词关键词匹配结果。
- 正常生成流程每次随机等待约 5–8 秒，并展示排队、生成、下载和保存进度。
- 支持成功、快速、慢速、服务失败、超时、离线和取消场景。
- 生成结果保存到设备本地，历史记录使用 SwiftData 管理。
- 文化、学习、社区和市集主内容均随 App 打包；只有外部资料链接需要网络。
- 当前不会调用付费 AI、不会产生真实交易，也没有真实社区账号或后端依赖。

## 功能概览

| 模块 | 内容 |
|---|---|
| 文化 | 六条文化线索、专题导读、馆藏/文章/视频来源链接 |
| 学习 | 微课程、针法步骤、阶段练习与本地演示流程 |
| AI 创作 | 结构化创作简报、文字/语音/参考图输入、Mock 生图 |
| 作品 | 本地保存、历史记录、收藏、分享、删除 |
| 社区 | 六条创作记录、分类筛选、开放馆藏来源、可用的本地研习交流 |
| 市集 | 现货、AI 定制和纹样授权的比赛演示流程 |

## 快速开始

### 环境要求

- macOS
- Xcode 26 或更新版本
- iOS 26.0 或更新版本的模拟器/真机

### 运行

```bash
git clone https://github.com/chulakarins/suxiu.git
cd suxiu
open "suxiu test.xcodeproj"
```

在 Xcode 中选择 `suxiu test` Scheme 和一个 iOS 模拟器，按 `⌘R`。当前版本不需要配置服务器地址或 API Key。

### 命令行验证

如果 Xcode 安装在 `/Applications/Xcode-beta.app`：

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
xcodebuild -project "suxiu test.xcodeproj" \
  -scheme "suxiu test" \
  -destination "generic/platform=iOS Simulator" \
  CODE_SIGNING_ALLOWED=NO build
```

测试命令和模拟器选择方法见[离线开发手册](./OFFLINE_DEVELOPMENT_GUIDE.md)。

## 推荐演示路线

1. 在“文化”查看苏绣线索与专题资料。
2. 切换“学习”，打开一节针法课程。
3. 点击底部中央 AI 按钮，选择创作参数并输入“荷塘里的白鹤”。
4. 等待约 5–8 秒，展示生成结果、工艺建议和“演示素材”标记。
5. 打开右上角菜单查看生成历史，再尝试收藏或分享。
6. 进入“社区”，筛选“馆藏研习”，打开来源或点击“交流”。
7. 最后进入“市集”，说明从数字创意到定制流程的产品设想。

## Mock 生图流程

```text
创作简报 + 提示词
        ↓
ImageGenerating 统一接口
        ↓
MockImageGenerator（关键词匹配 / 稳定回退）
        ↓
本地 JPEG 数据
        ↓
Application Support/GeneratedWorks
        ↓
SwiftData GenerationRecord（仅保存相对路径）
```

Mock 设置入口：AI 创作页右上角 `…` → `Mock 开发设置`。比赛前建议点击“恢复演示默认设置”。

## 核心目录

```text
suxiu test/
├── Core/
│   ├── Configuration/       # 服务选择与 Mock 配置
│   ├── Generation/          # 生图协议、状态和错误定义
│   └── Storage/             # 图片文件与 SwiftData 记录
├── Features/
│   ├── AIGenerate/          # AI 创作、历史和开发设置
│   ├── Experience/          # 文化、学习、社区、市集
│   └── Voice/               # 语音输入与转写
├── Services/Mock/           # Mock 生成器、场景和素材目录
├── Resources/MockImages/    # 19 张本地候选图与清单
└── Assets.xcassets/         # 界面与开放馆藏图片
```

## 数据与离线边界

- 生图素材、社区图片和主要文本均在 App 包内。
- 生成图片保存在应用的 `Application Support/GeneratedWorks`。
- SwiftData 只保存图片相对路径，不保存大体积图片二进制。
- 删除作品时先删除数据库记录，再清理对应文件，避免留下损坏历史项。
- 文化资料、视频和开放馆藏的超链接需要网络；断网不影响核心页面与 Mock 生图。

## 文档

- [离线开发手册](./OFFLINE_DEVELOPMENT_GUIDE.md)
- [项目体检报告](./PROJECT_HEALTH_CHECK.md)
- [文化资料来源](./CULTURE_SOURCES.md)
- [图片来源与许可](./IMAGE_SOURCES.md)
- [视频来源](./VIDEO_SOURCES.md)
- [后端开发部署指南](./后端开发部署指南.md)（未来真实服务参考，不是当前运行依赖）

## 正式 AI 接入方向

UI 依赖 `ImageGenerating` 协议。未来接入正式服务时，实现一个新的生成器并在 `AppEnvironment` 中切换即可；图片仍应先下载并保存为本地文件，再写入历史记录。不要在客户端仓库中提交 API Key。

## 项目边界

- “AI 工艺建议”、价格、工时、专家点评、用户数据和订单均为比赛演示内容。
- 社区开放馆藏图片明确标注来源与许可，不冒充真实用户原创。
- 外部文章与视频只提供原页面链接，不下载或二次发布。

## License

源代码许可请以仓库中的许可证文件为准；第三方图片、文字和视频分别遵循来源文档中标注的许可与使用条件。
