# 通用 iOS 无签名 IPA 编译器

**一个仓库，编译任意 iOS 项目。** 不用给每个项目单独写 workflow，也不用管项目是用什么语言写的。

---

## 这个仓库是干什么的

把任意一个 iOS 项目的地址填进来，点一下运行，GitHub 就会在它自己的 macOS 机器上把项目编译成 **无签名的 IPA 文件**，然后自动发到 Release 里给你下载。

编译全程在 GitHub 的服务器上跑，本机不需要装 Xcode、不需要 Mac、不需要任何开发环境。

产出的 IPA 是**未签名**的，安装方式自己解决（TrollStore 巨魔、AltStore 自签、Sideloadly 等都可以）。

---

## 怎么用（三步）

### 第一步：打开 Actions 页面

```
https://github.com/<你的账号>/ios-ipa-builder/actions/workflows/build-any.yml
```

### 第二步：点右边的 `Run workflow`，填几个空

| 字段 | 填什么 | 例子 |
|---|---|---|
| `repo` | 要编译的项目地址 | `某个账号/某个仓库` 或完整 `https://github.com/xxx/yyy` |
| `ref` | 分支、tag 或 commit | `main`（默认） |
| `kind` | 项目类型，不确定就填 `auto` | `auto` / `flutter` / `rn` / `xcode` |
| `app_name` | 产物文件名，随便起 | `myapp` |
| `flutter_ver` | 只有 Flutter 项目才需要 | `3.27.4`（默认） |
| `sub_dir` | 项目在子目录时填 | 留空表示仓库根目录 |
| `scheme` | 手动指定 Xcode scheme | 留空自动探测 |

### 第三步：等 15～30 分钟，去 Releases 拿文件

```
https://github.com/<你的账号>/ios-ipa-builder/releases
```

每次编译会生成一个 tag 为 `ipa-<时间>-r<运行号>` 的 Release，里面就是 IPA。

---

## 支持哪几种项目

| 类型 | `kind` | 说明 |
|---|---|---|
| Flutter | `flutter` | 用 `flutter build ipa --no-codesign`，最顺畅 |
| React Native | `rn` | 用 `xcodebuild`，需要先 `npm install` + `pod install` |
| 原生 Xcode | `xcode` | `.xcodeproj` / `.xcworkspace`，直接 `xcodebuild archive` |
| 自动判断 | `auto` | 脚本自己看仓库里有什么文件来决定 |

**不支持**：纯 Android 项目、纯 Web 项目、没有 iOS 工程的纯命令行工具。这类项目需要先自己写一个 iOS 壳。

---

## 免费的额度怎么算（重要）

GitHub Free 计划每月给 2000 分钟 Actions 时间，但 **macOS 机器按 10 倍计算**，也就是实际只有 **200 分钟**。

- 一次 Flutter 编译约 15～25 分钟 → 消耗 150～250 分钟额度
- 也就是说：**一个月大概只够编译 1～2 次**

额度用完了要等下个月重置，或者升级付费计划。

**降低消耗的办法：**
- 缓存命中会快很多（第一次慢，后面快）
- 别重复编译同一个提交
- 本地有 Mac 的话，用自建 runner 不消耗额度

---

## 产物说明

产出的文件名形如 `myapp-unsigned.ipa`。

它是标准 IPA 结构（一个 zip 包，里面是 `Payload/xxx.app`），只是 `.app` 没有签名。
- 巨魔（TrollStore）直接装
- 自签工具需要先重签再装

每个 Release 同时附了 sha256，可以用它校验文件是否完整。

---

## 常见问题

**编译失败了怎么办？**
去 Actions 页面点开那次运行，看哪一步红了。常见的三类：
1. 依赖装不上（Flutter 版本不对、pod 源不通）→ 调 `flutter_ver`
2. 找不到 scheme 或工程文件 → 填 `scheme` 或 `sub_dir`
3. 项目本身有编译错误 → 上游代码的问题，不是这个 workflow 的问题

**可以编译私有仓库吗？**
可以。在本仓库 Settings → Secrets and variables → Actions 里新增 `SOURCE_TOKEN`（一个有 repo 读权限的 PAT），workflow 会用这个令牌去拉私有代码。

**会不会改到原项目？**
不会。每次都是全新 clone 到临时目录，编译完就销毁，不推送任何东西回原仓库。

**产物没有图标 / 打不开？**
无签名 IPA 装上去之后，部分系统功能（推送、钥匙串、iCloud）会受限，这是签名缺失导致的，属正常现象。

---

## 仓库结构

```
.github/workflows/build-any.yml   核心：万能编译流程
scripts/detect.sh                 自动判断项目类型
scripts/build-flutter.sh          Flutter 构建
scripts/build-xcode.sh            原生 / RN 构建
```

想改行为，改脚本即可，不用动 workflow。
