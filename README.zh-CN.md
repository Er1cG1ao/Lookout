<p align="center">
  <img src="Assets/AppIcon.png" width="128" alt="Lookout 应用图标">
</p>

# Lookout

**转头离开，屏幕自动模糊。**

轻量的原生 macOS 菜单栏应用，用摄像头和 Apple Vision 在本机估计头部朝向。转头或离座后模糊屏幕，回正后恢复清晰。

[English](README.md) · **简体中文**

[下载](https://github.com/Er1cG1ao/Lookout/releases) · [使用教程](Docs/TUTORIAL.zh-CN.md) · [开发说明](Docs/DEVELOPMENT.md) · [反馈](https://github.com/Er1cG1ao/Lookout/issues)

**公开原型 · 0.1.1。** 检测人脸存在和头部朝向，**不识别身份，也不精确追踪眼球视线**。其他人也可能解除遮挡；视觉遮挡不能替代系统锁屏。

## 主要功能

- **适应侧置摄像头：** 以看着屏幕时的自然坐姿为基准，无需正对镜头。
- **水平、垂直独立转轮：** 实时指针、数字输入、分别校准或同时校准。
- **四个方向独立设置：** 向左、向右、抬头、低头可用不同阈值，垂直保护可单独关闭。
- **延迟与恢复缓冲：** 调整转头、无人和回正的等待时间，减少临界角度闪烁。
- **多屏幕覆盖：** 转头、人脸或朝向丢失、画面中断可触发；模糊接口失败时改用不透明遮挡。
- **菜单栏运行：** 设置打开时显示 Dock 图标，⌘W 关闭后回到菜单栏，可随时暂停。

使用 Swift、SwiftUI、AppKit、AVFoundation 和 Vision，无内置浏览器、下载模型、账号或网络服务。文档提供中英文，当前界面为简体中文。

## 安装与开始

需要 **Apple Silicon（M 系列）、macOS 14+** 和可用摄像头。暂不提供 Intel 安装包。

1. 从 [Releases](https://github.com/Er1cG1ao/Lookout/releases) 的 **Assets** 下载 DMG 或 ZIP；原型标记为 **Pre-release**。
2. 退出旧版，将 `Lookout.app` 拖入「应用程序」。
3. 打开并允许摄像头权限，选择设备，必要时调整画面旋转。
4. 自然坐好、看着屏幕，点击「同时校准」并保持约一秒；也可分别校准，再用转轮微调。
5. 调整角度，按需启用垂直保护，点击「应用并开始保护」。

打开设置会暂时解除遮挡；未应用就关闭会放弃本次修改。每次启动需手动开始保护。详见[教程](Docs/TUTORIAL.zh-CN.md)。

应用使用本机临时签名，**尚未经过 Apple 公证**。首次打开若被拦截，请确认来源后到「隐私与安全性」允许打开；不需要关闭系统安全保护。

## 范围与隐私

- 画面仅在内存中处理，不录制、不保存、不上传；不使用麦克风，不发起网络请求。
- 保护与预览时摄像头持续开启，系统使用提示保持可见。暂停并关闭设置后释放摄像头。
- 人脸检测不等于身份或注意力确认。局部遮脸可在人脸框仍在时导致角度跳动，暗光、眼镜和位置也可能影响检测。
- 使用私有接口 `CGSSetWindowBackgroundBlurRadius`。系统升级可能影响模糊效果；接口缺失或失败时改用不透明遮挡，返回成功也仍需实机确认。
- 不提供锁屏、认证或防截图功能，菜单栏有意保留操作入口。
- 配置仅保存在本机 UserDefaults，不录入人脸或保存生物特征模板。

## 从源码构建

安装当前版本 Apple Command Line Tools 或 Xcode：

```sh
git clone https://github.com/Er1cG1ao/Lookout.git
cd Lookout
bash build.sh
bash test.sh
```

输出 `build/Lookout.app`，构建不会安装应用或启用摄像头。打包与验证见[开发说明](Docs/DEVELOPMENT.md)。

## 反馈与贡献

请在 [Issues](https://github.com/Er1cG1ao/Lookout/issues) 提供应用／macOS 版本、摄像头位置、步骤、预期及实际表现。遮挡问题请注明是人脸框消失还是角度跳变。请移除个人信息，避免上传本人或他人的摄像头画面。

[中文教程](Docs/TUTORIAL.zh-CN.md) · [English guide](Docs/TUTORIAL.md) · [开发说明](Docs/DEVELOPMENT.md) · [更新记录](CHANGELOG.md)

## 许可与参考

[MIT](LICENSE)。[HeadOrbit](https://github.com/Cogria-AI/HeadOrbit) 提供覆盖层及延迟／迟滞参考；[Glance](https://github.com/jonnyoo/glance) 提供摄像头与 Vision 管线参考。不含 Glance 身份识别模型。见[第三方声明](THIRD_PARTY_NOTICES.md)；原创图标由 [`Support/make-icon.swift`](Support/make-icon.swift) 绘制。
