# CLAUDE.md - AI摄影助手 App

## 项目概述
项目名称：智眸AI相机 (AICam Coach)
类型：跨平台移动应用 (Android & iOS)
框架：Flutter
AI能力：多模态大模型分析 + 端侧姿态检测

## 技术栈约束
- **必须使用 Flutter** 作为跨平台框架
- **状态管理**：使用 Riverpod 或 Bloc
- **相机插件**：优先使用 camerawesome
- **AI API**：支持 OpenAI GPT-4V / Claude Vision / Gemini Vision / 国内智谱GLM-4V等多模型切换
- **端侧检测**：MediaPipe Holistic 用于实时姿态检测
- **本地存储**：Hive 或 SQLite
- **架构模式**：Clean Architecture + MVVM

## 编码规范
- 使用 Dart 3.0+，启用 null safety
- 遵循 Effective Dart 编码规范
- 组件命名采用 PascalCase，函数和变量采用 camelCase
- 每个功能模块必须有对应的单元测试
- AI 调用必须实现缓存机制，减少重复请求
- 相机预览流需使用 `compute()` 进行 isolate 处理，避免 UI 卡顿

## 项目结构

lib/
├── main.dart
├── app/
│ ├── routes/
│ └── theme/
├── features/
│ ├── camera/
│ │ ├── presentation/
│ │ ├── domain/
│ │ └── data/
│ ├── reference/
│ ├── analysis/
│ └── gallery/
├── core/
│ ├── ai/
│ ├── camera/
│ ├── storage/
│ └── utils/
└── shared/
├── widgets/
└── models/

## 关键约束
- 相机预览必须保持 ≥ 30fps 流畅度
- AI 分析频率：最多每秒 2 次，避免过度消耗
- 首次冷启动时间 < 3 秒
- 支持离线基础构图分析（端侧模型降级）
- 隐私保护：AI 分析图片不上传原始图，仅上传压缩后的关键特征帧

## 开发阶段
1. Phase 1: 基础相机功能 + UI框架搭建
2. Phase 2: 端侧姿态检测集成
3. Phase 3: AI 大模型分析集成
4. Phase 4: 参考图模板系统
5. Phase 5: 实时反馈UI与语音播报
6. Phase 6: 高级参数控制与优化

## 注意事项
- 相机权限处理：iOS 需 Info.plist 配置，Android 需 AndroidManifest 配置
- AI API 密钥需使用环境变量或远程配置，不可硬编码
- 图片保存需适配 Android Scoped Storage 和 iOS Photo Library