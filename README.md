# WebRTC-Build

[![GitHub tag (latest SemVer)](https://img.shields.io/github/tag/shiguredo-webrtc-build/webrtc-build.svg)](https://github.com/shiguredo-webrtc-build/webrtc-build)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Actions Status](https://github.com/shiguredo-webrtc-build/webrtc-build/workflows/build/badge.svg)](https://github.com/shiguredo-webrtc-build/webrtc-build/actions)

## About Shiguredo's open source software

We will not respond to PRs or issues that have not been discussed on Discord. Also, Discord is only available in Japanese.

Please read https://github.com/shiguredo/oss/blob/master/README.en.md before use.

## 关于时雨堂的开源软件

使用前请阅读<https://github.com/shiguredo/oss>

## 关于webrtc-build

我们为各种环境构建WebRTC，提供二进制文件。

## 下载

[发布](https://github.com/melpon/webrtc-build/releases) 请从这里下载。

## 包装里的内容

- WebRTC库(WebRTC .lib或libwebrtc.a)
- WebRTC的头文件
- WebRTC版本信息

## 现在提供的构建

- windows_x86_64
- windows_arm64
- macos_arm64
- raspberry-pi-os_armv6 (Raspberry Pi Zero, 1)
- raspberry-pi-os_armv7 (Raspberry Pi 2, 3, 4)
- raspberry-pi-os_armv8 (Raspberry Pi Zero 2, 3, 4)
- ubuntu-18.04_armv8
  - Jetson Nano
  - Jetson Xavier NX
  - Jetson AGX Xavier
- ubuntu-20.04_armv8
  - Jetson Xavier NX
  - Jetson AGX Xavier
  - Jetson Orin NX
  - Jetson AGX Orin
- ubuntu-20.04_x86_64
- ubuntu-22.04_x86_64
- android_arm64
- ios_arm64

### hololens2关于构建

- 支持的分支是support/hololens2。
- 最新的libwebrtc追随是有偿的
- 修正错误是有偿的。

## 廃止

- macOS x86_64 废除
  - 到2022年6月，它被取消了。
- Ubuntu 18.04 x86_64 废除
  - 2022 年 6 月，它被取消了。
- Jetson 向け ARM 版 Ubuntu 18.04 废除
  - 2023 年 4 月，它被取消了。

## H.264 (AVC)和H.265 (HEVC)许可证

时雨堂提供的libwebrtc已构建二进制文件中不包含H.264和H.265编译码器。

### H.264

H.264对应[Via LA Licensing](https://www.via-la.com/)(原MPEG-LA)取得联系，确认不成为专利费的对象。。

如果时雨堂提供依赖于终端用户的PC /设备中已有的AVC / H.264编码器/解码器的产品，
软件产品不属于AVC授权的对象，也不属于专利费的对象。

### H.265

H.265支持联系以下两个团体，仅利用H.265硬件加速器，
正在确认H.265分发可利用的二进制的事，不需要许可证。

另外，在OSS中公开了仅使用H.265硬件加速器的支持H.265的SDK，
分发已构建的二进制文件是不需要许可证的。

- [Access Advance](https://accessadvance.com/ja/)
- [Via LA Licensing](https://www.via-la.com/)

## 许可证

Apache License 2.0

```
Copyright 2019-2023, Wandbox LLC (Original Author)
Copyright 2019-2023, tnoho (Original Author)
Copyright 2019-2023, Shiguredo Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
