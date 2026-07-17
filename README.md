# KuiklyHostKit

Kuikly iOS 宿主接入标准包集合，对外只暴露一个稳定 SPM 包：

- `KuiklyIOSHost`：宿主侧统一接入入口

渲染核心 `OpenKuiklyIOSRender` 已合并为包内内部目标，由 `KuiklyIOSHost` 统一依赖并对宿主屏蔽细节。

## 支持的接入方式

当前仅支持通过 Swift Package Manager（SPM）接入。

## 1. 包的职责

### `KuiklyIOSHost`

负责把宿主侧接 Kuikly 的能力收敛到统一入口里，主要包含：

- 宿主初始化
- 页面承载
- 路由和结果回传
- Native 能力桥接
- 渲染适配注册
- 扩展 provider 装配

## 2. 推荐接入方式

### 宿主 App

宿主工程只引入 `KuiklyIOSHost`。

## 3. 快速接入步骤

### Step 1: 添加 SPM

1. 在 Xcode 里打开宿主工程，进入 `File > Add Package Dependencies...`
2. 添加 `KuiklyIOSHost` 对应的远程 Git 地址：[https://github.com/hurui-open/IOS-KuiklyIOSHost.git](https://github.com/hurui-open/IOS-KuiklyIOSHost.git)
3. 在产品列表里只勾选 `KuiklyIOSHost`

### Step 2: 完成最小初始化

先用下面这段代码打通最小链路。

```swift
import KuiklyIOSHost

let support = KuiklyHostSupportConfiguration.defaultConfiguration()

let runtimeInstaller = KuiklyHostRuntimeInstaller {
    // 在这里安装你的 OpenKuikly 运行时
}

KuiklyIOSHostManager.initializeWithRuntimeInstaller(
    runtimeInstaller,
    supportConfiguration: support,
    renderAdapterProvider: nil,
    providers: [
        KuiklyNavigationPageProvider()
    ]
)
```

### Step 3: 验证最小链路

先确认下面三项都正常：

- App 能完成初始化
- Kuikly 页面能打开
- 页面返回宿主能正常工作

### Step 4: 承载页面

先用 `KuiklyNavigationPageProvider` 跑通页面承载。

### Step 5: 按需补能力

再按业务需要补 `NativeRoute`、`Media`、`Scan`、`ProjectBridge` 等 provider。

## 4. 标准接入内容

在最小链路跑通后，标准接入通常再补齐下面这些内容：

### 基础项

- 一个页面承载 provider，推荐先用 `KuiklyNavigationPageProvider`
- 一个统一的初始化入口
- 渲染适配器，默认可先传 `nil`

### 按需扩展

- `KuiklyHostNativeRouteProvider`
- `KuiklyHostMediaProvider`
- `KuiklyHostScanProvider`
- `KuiklyHostProjectBridgeProvider`
- `KuiklyHostUiProvider`

## 5. 页面打开示例

```swift
let vc = KuiklyRenderViewController(pageName: "HomePage", pageData: [:])
navigationController?.pushViewController(vc, animated: true)
```

## 6. 接入检查清单

- `KuiklyIOSHost` 已添加到宿主工程
- `runtimeInstaller` 已传入
- `supportConfiguration` 已按项目需要完成配置
- 页面承载 provider 已注册
- 初始化入口只保留一处
- 页面打开和返回链路已验证

## 7. 使用 `kuikly-ios-host` skill

如果你希望 AI 按这套仓库标准帮你接入宿主项目，可以直接使用 `kuikly-ios-host` skill。

### 适合的提法

- “帮我用 `kuikly-ios-host` 接入当前 iOS 项目”
- “请按 `KuiklyHostKit` 的标准生成宿主侧 `Kuikly/` 目录”
- “先做最小可运行版本，再按需补 provider”

### skill 会做什么

- 帮宿主项目引入 `KuiklyIOSHost`
- 生成 `KuiklyManager` 作为唯一入口
- 生成最小可运行宿主骨架
- 预留 provider 扩展位
- 把接入代码放到宿主工程的 `Kuikly/` 目录

### skill 不会做什么

- 不修改 `KuiklyIOSHost` 本体实现
- 不要求接入方调整包内部源码
- 不强制一次补全所有业务 provider

## 8. 适用场景

- 新 iOS 项目接入 Kuikly
- 需要标准化宿主封装
- 希望 AI 按统一模板生成宿主代码
- 宿主侧按需扩展接入能力
