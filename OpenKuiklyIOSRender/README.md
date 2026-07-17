# OpenKuiklyIOSRender

Kuikly iOS 的渲染核心 SPM 包，负责渲染能力本体。

当前版本：`2.20.1`

## 定位

这个包只负责渲染核心能力，不承载宿主初始化、页面承载和宿主桥接编排。

## 使用方式

- 宿主工程通常只需要依赖 `KuiklyIOSHost`
- 业务模块只有在需要直接使用渲染核心 API 时，才单独依赖 `OpenKuiklyIOSRender`

## 版本关系

- 当前 `OpenKuiklyIOSRender` 版本：`2.20.1`
- `KuiklyIOSHost` 会声明它依赖的 `OpenKuiklyIOSRender` 版本
- 宿主工程通常只需要更新 `KuiklyIOSHost`
