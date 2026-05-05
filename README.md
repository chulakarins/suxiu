<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS%2026%2B-blue?style=for-the-badge&logo=apple" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-6.0-orange?style=for-the-badge&logo=swift" alt="Swift">
  <img src="https://img.shields.io/badge/SwiftUI-5.0-purple?style=for-the-badge&logo=swift" alt="SwiftUI">
  <img src="https://img.shields.io/badge/AI-DashScope-green?style=for-the-badge&logo=alibaba" alt="AI">
  <img src="https://img.shields.io/badge/License-MIT-lightgrey?style=for-the-badge" alt="License">
</p>

<h1 align="center">🧵 苏绣 AI · Suxiu AI</h1>

<p align="center">
  <strong>当千年苏绣遇到人工智能</strong><br>
  <em>When Millennia-Old Suzhou Embroidery Meets Artificial Intelligence</em>
</p>

<p align="center">
  <img src="https://readme-typing-svg.demolab.com?font=Noto+Sans+SC&weight=500&size=18&duration=3000&pause=1000&color=8B5E3C&center=true&vCenter=true&width=500&lines=%E4%BC%A0%E7%BB%9F%E9%9D%9E%E9%81%97+%C3%97+%E4%BA%BA%E5%B7%A5%E6%99%BA%E8%83%BD;%E4%BB%8E%E5%88%9B%E6%84%8F%E5%88%B0%E5%AE%9E%E7%89%A9%C2%B7%E4%B8%80%E9%94%AE%E6%88%90%E7%BB%A3;%E8%AE%A9%E6%AF%8F%E4%B8%AA%E4%BA%BA%E9%83%BD%E6%88%90%E4%B8%BA%E8%8B%8F%E7%BB%A3%E8%AE%BE%E8%AE%A1%E5%B8%88" alt="Tagline">
</p>

---

## 📖 项目简介 · About

**苏绣 AI** 是一个创新的 **C2M（Customer-to-Manufacturer）** 平台应用，将国家级非物质文化遗产「苏绣」与前沿 AI 技术深度融合。用户只需通过**文字描述、语音输入或上传参考图片**，AI 即可在数十秒内生成专业的苏绣设计图，并一键连接合作工厂进行实物制作 —— 实现从**创意到实物**的完整数字化闭环。

> *Suxiu AI is an innovative C2M platform that merges China's national intangible cultural heritage — Suzhou Embroidery — with cutting-edge AI. Describe your idea in text, voice, or images, and the AI generates professional embroidery designs, then connects directly to partner factories for physical production.*

---

## ✨ 核心亮点 · Highlights

<table>
  <tr>
    <td width="50%">
      <h3>🎨 AI 创意生成</h3>
      <p>接入阿里云 DashScope（通义万相）大模型，支持文生图、图生图，30 秒内生成多套专业苏绣设计方案</p>
    </td>
    <td width="50%">
      <h3>🎤 多模态输入</h3>
      <p>支持文字描述、语音录入（实时语音转文字）、参考图片上传，让创意表达无障碍</p>
    </td>
  </tr>
  <tr>
    <td>
      <h3>🧬 C2M 商业闭环</h3>
      <p>从创意到设计、从设计到生产，完整的数字化链路，打通非遗商业化最后一公里</p>
    </td>
    <td>
      <h3>🫧 iOS 26 Liquid Glass</h3>
      <p>率先适配 Apple 最新 Liquid Glass 设计语言，毛玻璃质感的沉浸式交互体验</p>
    </td>
  </tr>
  <tr>
    <td>
      <h3>🏛️ 文化传承创新</h3>
      <p>用科技让千年苏绣技艺焕发新生，降低传统工艺的使用门槛，让更多人感受非遗之美</p>
    </td>
    <td>
      <h3>🛍️ 作品市场</h3>
      <p>内置文创商城，用户可以浏览、购买 AI 生成的设计作品，或将其制作为实物绣品</p>
    </td>
  </tr>
</table>

---

## 🏗️ 技术架构 · Architecture

```
┌─────────────────────────────────────┐
│           📱 SwiftUI Layer           │
│   HomeView · MarketView · Profile    │
│   VoiceRecorder · ImagePicker       │
├─────────────────────────────────────┤
│           🧠 ViewModel Layer         │
│   ContentViewModel · AI Service     │
├─────────────────────────────────────┤
│           🌐 API / AI Layer          │
│   DashScope (通义万相) · REST API    │
├─────────────────────────────────────┤
│           💾 Data Layer              │
│   Core Data · Cloud Database        │
└─────────────────────────────────────┘
```

### 技术栈 · Tech Stack

| 层级 | 技术选型 | 说明 |
|------|---------|------|
| 🖥️ 前端框架 | **SwiftUI 5.0** | Apple 最新声明式 UI 框架 |
| 🎯 最低版本 | **iOS 26.0** | 面向下一代 Apple 操作系统 |
| 🛠️ 开发环境 | **Xcode 26.2** | 最新开发工具链 |
| 🏛️ 架构模式 | **MVVM** | Model-View-ViewModel |
| 🤖 AI 引擎 | **阿里云 DashScope** | 通义万相文生图 / 图生图 |
| 🎤 语音识别 | **Speech Framework** | 实时语音转文字（中英文） |
| 📦 本地存储 | **Core Data** | Apple 原生持久化方案 |
| 🎨 设计语言 | **Liquid Glass** | iOS 26 全新视觉风格 |

---

## 📂 项目结构 · Structure

```
suxiu test/
├── 📱 Core/Base/
│   └── LiquidGlassView.swift        # iOS 26 Liquid Glass 扩展
├── 🎨 Features/
│   ├── Profile/ProfileView.swift     # 个人中心
│   └── Voice/VoiceRecorder.swift     # 语音录制 + 实时转写
├── 🏠 HomeView.swift                 # 主界面（AI 生成 + Tab 导航）
├── 🧠 ContentView.swift              # 内容视图
├── 🚀 suxiu_testApp.swift            # 应用入口
├── 📦 Item.swift                     # 数据模型
└── 📋 suxiu-test-Info.plist          # 应用配置
```

---

## 🚀 快速开始 · Quick Start

### 环境要求

- macOS 26+ with Xcode 26.2+
- iOS 26.0+ 模拟器或真机
- 阿里云 DashScope API Key

### 运行项目

```bash
# 1. 克隆仓库
git clone https://github.com/chulakarins/suxiu.git
cd suxiu

# 2. 打开 Xcode 项目
open "suxiu test.xcodeproj"

# 3. 配置 API Key
# 编辑 suxiu_testApp.swift，填入你的 DashScope API Key

# 4. 选择 iOS 26 模拟器，运行 (⌘R)
```

---

## 🗺️ 路线图 · Roadmap

- [x] AI 文生图核心功能
- [x] 语音输入 + 实时转文字
- [x] iOS 26 Liquid Glass 适配
- [x] 完整的项目文档 & 设计系统
- [ ] 图生图（以图搜图/风格迁移）
- [ ] 多针法识别与推荐
- [ ] 工厂订单系统对接
- [ ] 用户作品社区
- [ ] iPad / macOS 多端适配
- [ ] App Store 上架

---

## 📄 文档 · Documentation

| 文档 | 说明 |
|------|------|
| [项目综合分析报告](./项目综合分析报告.md) | 完整的技术架构、代码分析、安全审计 |
| [设计系统文档](./设计系统文档.md) | 颜色/字体/间距/动效设计规范 |
| [后端开发部署指南](./后端开发部署指南.md) | API 设计、数据库、部署方案 |

---

## 🎯 创新价值 · Innovation

### 🧬 非遗 × AI：文化科技的范式创新

将苏绣这一拥有 2000 余年历史的非物质文化遗产，通过生成式 AI 技术进行数字化解构与再创作，**打破传统刺绣工艺「高门槛、低效率、难传播」的困局**，让每个人都能成为苏绣设计师。

### 🔗 C2M：从创意到实物的完整闭环

区别于传统「AI 生图」类应用，苏绣 AI 构建了完整的 C2M 商业链路 —— AI 不仅生成设计图，更与实物生产环节深度打通，**让数字创意真正落地为可触摸的实体产品**。

### 🌏 文化出海：让世界看见中国非遗

以科技为媒介，将中国传统工艺推向全球市场。海外用户可通过英文界面体验「东方高定」的魅力，实现文化价值与商业价值的双循环。

---

## 🤝 贡献者 · Contributors

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/chulakarins">
        <img src="https://github.com/chulakarins.png" width="80px" style="border-radius:50%" alt="Chulakarins"/>
        <br />
        <b>Chulakarins</b>
      </a>
      <br />
      <sub>Creator & Lead Developer</sub>
    </td>
  </tr>
</table>

---

<p align="center">
  <sub>Made with ❤️ for Suzhou Embroidery | 以科技致敬千年匠心</sub>
</p>

---

<p align="center">
  <a href="https://github.com/chulakarins/suxiu/stargazers">
    <img src="https://img.shields.io/github/stars/chulakarins/suxiu?style=social" alt="Stars">
  </a>
  <a href="https://github.com/chulakarins/suxiu/network/members">
    <img src="https://img.shields.io/github/forks/chulakarins/suxiu?style=social" alt="Forks">
  </a>
</p>
