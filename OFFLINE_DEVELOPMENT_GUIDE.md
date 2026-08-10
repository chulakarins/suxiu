# 锦绣智造：离线开发手册

更新时间：2026-08-02

## 1. 这份手册解决什么问题

当前版本已经把 AI 生图替换为本地 Mock。即使没有 GPT Plus、没有 API Key、没有后端服务或比赛现场断网，仍可继续开发和演示核心流程。

离线可用：文化与学习页面、社区与市集演示、Mock 生图、本地历史、收藏、删除和系统分享。

需要网络：打开文化文章、视频和馆藏原页面。它们是扩展资料，不影响核心流程。

## 2. 环境与首次运行

需要 macOS、Xcode 26+ 和 iOS 26.0+ 模拟器或真机。

```bash
git clone https://github.com/chulakarins/suxiu.git
cd suxiu
open "JinxiuZhizao.xcodeproj"
```

打开后选择 `JinxiuZhizao` Scheme，选择 iOS 模拟器并运行。不需要填写 API Key，也不需要启动 `suxiu-backend`。

如果命令行没有使用正确的 Xcode，可临时指定：

```bash
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
```

## 3. 比赛前的固定设置

1. 打开 AI 创作页。
2. 点击右上角 `…`，进入“Mock 开发设置”。
3. 点击“恢复演示默认设置”。
4. 确认场景是“正常成功”，并开启“演示素材”标记。
5. 先生成一次“荷塘里的白鹤”，确认结果能进入历史记录。
6. 关闭 Wi-Fi 再生成一次，确认核心流程仍能完成。

注意：“离线”Mock 场景是用来展示错误状态的测试开关，并不代表 App 真正依赖网络。测试后一定恢复默认。

## 4. Mock 系统工作方式

关键文件：

| 文件 | 作用 |
|---|---|
| `Core/Generation/GenerationTypes.swift` | `ImageGenerating` 协议、进度状态、结果和错误 |
| `Services/Mock/MockImageGenerator.swift` | 模拟排队、进度、异常和读取本地图片 |
| `Services/Mock/MockImageCatalog.swift` | 关键词匹配与稳定回退 |
| `Core/Configuration/AppEnvironment.swift` | 根据开发设置创建生成器 |
| `Core/Storage/GeneratedFileStore.swift` | 保存和删除生成图片 |
| `Core/Storage/GenerationRepository.swift` | SwiftData 生成记录 |
| `Features/AIGenerate/AIGenerateView.swift` | UI 与完整生成编排 |

正常场景总耗时随机约 5–8 秒。关键词匹配示例：

- “白鹤、荷花、荷塘” → 荷塘白鹤
- “牡丹、蝴蝶” → 牡丹花蝶
- “猫、白猫、宠物” → 花间白猫
- “江南、园林、水乡” → 江南水乡
- 未匹配关键词 → 根据提示词稳定选择三张默认图之一

相同的未知提示词会稳定获得相同回退图，便于重复演示。

## 5. 添加或替换 Mock 图片

1. 准备正方形 JPEG，建议 1254 × 1254、sRGB、质量约 90%。
2. 放入 `JinxiuZhizao/Resources/MockImages/`。
3. 在 `MockImageCatalog.entries` 或 `fallbackEntries` 增加条目。
4. 更新 `Resources/MockImages/manifest.json`。
5. 运行资源测试，确认图片被打进 App 包。

不要让 UI 长期直接读取 Downloads 或桌面文件；所有演示图片必须随 App 打包。

## 6. 本地数据

生成后的 JPEG 位于应用沙盒：

```text
Application Support/GeneratedWorks/<记录 UUID>.jpg
```

SwiftData 的 `GenerationRecord` 保存提示词、生成状态、是否 Mock、收藏状态和相对路径。数据库不保存图片 BLOB，也不依赖远程 URL。

卸载 App 或“抹掉模拟器内容”会删除这些历史数据。需要比赛预置作品时，请提前在目标设备生成，不要依赖另一台模拟器的数据。

## 7. 构建与测试

查看可用模拟器：

```bash
xcrun simctl list devices available
```

只检查编译：

```bash
xcodebuild -project "JinxiuZhizao.xcodeproj" \
  -scheme "JinxiuZhizao" \
  -destination "generic/platform=iOS Simulator" \
  CODE_SIGNING_ALLOWED=NO build
```

运行单元测试时，把设备名替换成电脑中存在的模拟器：

```bash
xcodebuild -project "JinxiuZhizao.xcodeproj" \
  -scheme "JinxiuZhizao" \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -parallel-testing-enabled NO \
  -only-testing:"JinxiuZhizaoTests/MockImageGeneratorTests" \
  test
```

`MockImageGeneratorTests` 会检查关键词匹配、稳定回退、19 张资源、5–8 秒耗时、离线、服务失败和取消。

## 8. 常见问题

### 点击生成后提示缺少素材

检查图片文件名、扩展名与 `MockImageCatalog` 是否完全一致，然后确认资源已进入 App target。

### 一直显示离线或失败

进入 AI 页右上角 `…` →“Mock 开发设置”→“恢复演示默认设置”。

### 模拟器不能拍照

模拟器通常没有相机。当前版本会显示提示，请改用“从相册选择”；真机可正常申请相机权限。

### 麦克风没有反应

第一次使用会申请麦克风和语音识别权限。若曾拒绝，请到系统设置中重新允许。模拟器的语音输入能力可能受宿主机音频设置影响，比赛现场建议同时准备文字输入。

### 历史图片不见了

确认 App 没有被卸载或更换 Bundle Identifier。若只剩损坏的旧模拟器数据，删除该条历史并重新生成。

### Xcode 找不到 SDK

确认使用 Xcode 26+；如果同时安装多个 Xcode，通过 `DEVELOPER_DIR` 指向正确版本。

### Xcode Beta 一直停在 Testing started

部分 Beta 版会在自动克隆模拟器时失去连接。先手动启动一个固定模拟器，再用它的设备 ID 运行测试，并关闭并行测试。项目编译通过但测试没有开始时，应先排查模拟器状态，而不是修改 Mock 逻辑。

## 9. 接入正式 AI 的契约

正式服务应实现 `ImageGenerating`：

```swift
protocol ImageGenerating: Sendable {
    func generate(
        prompt: String,
        referenceImageData: Data?,
        onProgress: @escaping GenerationProgressHandler
    ) async throws -> GeneratedImagePayload
}
```

推荐接入顺序：

1. 新建 `RealImageGenerator`，内部负责提交任务、轮询和下载图片。
2. 把服务错误映射为 `GenerationError`，不要让 UI 解析供应商错误。
3. 结果必须返回图片 `Data`；继续使用现有本地保存和历史记录流程。
4. 在 `AppEnvironment` 中增加 Mock/Real 切换，不直接改 ViewModel。
5. API Key 放在服务端或安全配置中，禁止提交到 GitHub。
6. 为超时、限流、无效响应、取消和断网增加测试。

这样切换真实服务时不需要重写 AI 页面、历史记录或分享功能。

## 10. 后续开发优先级

P0：维持离线演示可用；每次改动后跑构建和 Mock 测试。

P1：补 UI 自动化测试，覆盖首页 → AI → 生成 → 历史的固定路线。

P1：若准备真机比赛，固定签名团队、设备和 Bundle Identifier，提前安装并完整走一遍权限弹窗。

P2：接入正式服务适配器、后端密钥管理与真实账号体系。

P2：把社区本地讨论升级为真实持久化与审核体系。

## 11. 演示前 10 项检查

- [ ] 使用正确的提交版本并能正常编译
- [ ] Mock 场景恢复为“正常成功”
- [ ] “演示素材”标记已开启
- [ ] 19 张图片资源测试通过
- [ ] 已预生成至少一条历史作品
- [ ] 文字生成路线已走通
- [ ] 麦克风权限已处理，或决定只用文字输入
- [ ] 相册/相机备用输入已测试
- [ ] 外部链接打不开时有离线说明
- [ ] 设备电量、屏幕录制和勿扰模式已准备
