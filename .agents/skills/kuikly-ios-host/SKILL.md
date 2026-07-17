---
name: kuikly-ios-host
description: "Kuikly iOS 宿主接入助手。用于其他 iOS 项目快速、标准地接入 KuiklyIOSHost SPM，生成宿主侧 Kuikly/ 目录下的最小可运行初始化、页面承载、路由桥接与可扩展 provider 模板。适合需要 AI 辅助完成 Kuikly 宿主接入、但不修改 KuiklyIOSHost 内部实现的场景。"
---

# Kuikly iOS 宿主接入助手

## 适用场景

- 给新的 iOS 项目接入 `KuiklyIOSHost`。
- 让 AI 在宿主工程中新建 `Kuikly/` 目录并生成标准接入代码。
- 以 `KuiklyManager` 作为唯一主入口完成初始化。
- 先做最小可运行版本，再按需补 `NativeRouteProvider`、`MediaProvider`、`ScanProvider`、`ProjectBridgeProvider`。
- 只使用 `KuiklyIOSHost` 的公开能力，不修改它的内部实现。

## 核心原则

- **先接入 SPM，再生成宿主代码。** 如果项目还没有引入 `KuiklyIOSHost`，先补包依赖，再生成宿主侧代码。
- **宿主代码放到 `Kuikly/` 目录。** 默认生成 `Kuikly/Host/`、`Kuikly/Provider/`、`Kuikly/Bridge/`、`Kuikly/Demo/`。
- **默认不依赖 Bootstrap。** `Bootstrap` 只作为兼容旧架构或过渡方案，不作为标准入口。
- **`KuiklyManager` 负责全部初始化。** `runtimeInstaller`、`supportConfiguration`、`providers`、渲染适配器都优先集中到 `KuiklyManager`。
- **最小可运行优先。** 先确保能启动、能打开 Kuikly 页、能返回结果，再补业务 Provider。
- **不碰宿主外的实现细节。** 只围绕接入方宿主工程写代码，不要求修改 `kuiklyIOSHost` 源码。

## 标准输出目标

当用户要求“用这个 skill 接入”时，优先输出或生成以下内容：

1. `Kuikly/Host/KuiklyManager.swift`
2. `Kuikly/Host/KuiklyRenderAdapterProvider.swift`
3. `Kuikly/Host/KuiklyPageProvider.swift`
4. `Kuikly/Bridge/NativeProvider.swift`
5. `Kuikly/Provider/NativeRouteProvider.swift`（按需）
6. `Kuikly/Provider/MediaProvider.swift`（按需）
7. `Kuikly/Provider/ScanProvider.swift`（按需）
8. `Kuikly/Provider/ProjectBridgeProvider.swift`（按需）
9. `Kuikly/Demo/` 下的最小演示页或测试入口

## 推荐工作流

### Step 1: 先确认接入状态

先检查宿主项目是否已经完成以下事项：

- 是否已在 Xcode SPM 中添加 `KuiklyIOSHost`
- 是否存在 `Kuikly/` 目录
- 是否有统一的宿主启动入口
- 是否已有导航控制器或根页面可承载 Kuikly 页面

如果未接入 SPM，优先补这个步骤。

### Step 2: 生成最小宿主骨架

最小骨架只做三件事：

- 初始化 `KuiklyManager`
- 注册基础能力与渲染适配
- 打通一个可打开的 Kuikly 页面入口

建议输出的宿主结构：

```text
Kuikly/
  Host/
    KuiklyManager.swift
    KuiklyPageProvider.swift
    KuiklyRenderAdapterProvider.swift
  Bridge/
    NativeProvider.swift
  Provider/
  Demo/
```

### Step 3: 只做最小可运行初始化

`KuiklyManager` 负责统一装配这些内容：

- `runtimeInstaller`
- `supportConfiguration`
- `providers`
- 渲染适配器

如果接入方没有特殊要求，不要先拆成 `Bootstrap` + `Manager` 两层，直接用 `KuiklyManager` 单入口更清晰。

### Step 4: 生成 Provider 模板

默认先生成空实现或轻量实现，避免一上来把业务耦合进去：

- `NativeRouteProvider` 负责原生路由与页面跳转
- `MediaProvider` 负责媒体能力
- `ScanProvider` 负责扫码能力
- `ProjectBridgeProvider` 负责项目自定义桥接能力

如果用户只要求开箱即用，先不要强制补齐所有 provider。优先确保基础 host 可跑。

### Step 5: 补一个验证入口

至少给出一个 Demo 入口或调试按钮，用来验证：

- Kuikly 页面是否能打开
- 页面返回/关闭是否正常
- callback / result 是否能回传

## 生成规则

- **只用公开 API。** 不要要求接入方去改 `KuiklyIOSHost` 内部源码。
- **默认引用 SPM 包。** 生成的宿主代码应明确依赖 `import KuiklyIOSHost`，并假设包已通过 Xcode SPM 添加。
- **初始化集中管理。** 所有接入配置尽量在 `KuiklyManager` 内完成，避免分散到 AppDelegate、SceneDelegate、多个 provider 中。
- **按需扩展。** 只有当用户明确需要扫码、媒体、路由、桥接时，再补对应 provider。
- **代码放在 Kuikly 目录。** 不要把 AI 生成的宿主接入代码散落到项目各处。

## 你应该回答什么

当用户问“这个 skill 会做什么”时，优先说明：

- 会帮宿主项目引入 `KuiklyIOSHost` 的 SPM 包
- 会生成 `KuiklyManager` 作为唯一入口
- 会生成最小可运行宿主壳
- 会预留 provider 扩展位
- 会把 AI 生成内容放到宿主的 `Kuikly/` 目录
- 不会修改 `KuiklyIOSHost` 本体实现

## 最小可运行优先级

如果用户没有额外约束，默认顺序如下：

1. 引入 `KuiklyIOSHost` SPM
2. 生成 `KuiklyManager`
3. 打通页面承载与返回
4. 生成基础路由 / bridge 占位
5. 再补 `NativeRouteProvider`、`MediaProvider`、`ScanProvider`、`ProjectBridgeProvider`

## 常见排障

- **模块导入失败**：优先检查 SPM 是否已加入、包名是否一致、宿主目标是否勾选了该包。
- **页面打不开**：检查宿主是否真的走到了 `KuiklyManager` 初始化流程。
- **结果回调不通**：检查 bridge/provider 是否注册成功、回调 key 是否唯一。
- **找不到能力实现**：先确认是基础接入还是业务 provider；基础接入不要求一次补全所有能力。

## 使用说明

接到相关需求时，按这个判断：

- 用户说“帮我接入 Kuikly iOS 宿主” -> 使用本 skill
- 用户说“给另一个 iOS 项目做标准宿主接入” -> 使用本 skill
- 用户只想改 KuiklyIOSHost 内部源码 -> 不用本 skill，按源码维护思路处理

如果用户已经明确要做“开箱即用版本”，就默认产出最小可跑骨架，再补 provider 扩展位。
