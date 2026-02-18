# GitHub Actions 自动打包指南

## 🚀 快速开始

### 步骤1：创建GitHub仓库

1. 打开 https://github.com/new
2. 仓库名称：`vision-analyzer`
3. 选择 `Public` 或 `Private`
4. 点击 **Create repository**

### 步骤2：推送代码到GitHub

在终端中执行：

```bash
cd /Users/wanlongyi/project/vibe_project/glasess-analyze

# 添加远程仓库
git remote add origin https://github.com/您的用户名/vision-analyzer.git

# 推送代码
git branch -M main
git push -u origin main
```

### 步骤3：触发自动构建

推送代码后，GitHub Actions会自动开始构建：

1. 打开仓库页面
2. 点击 **Actions** 标签
3. 查看构建进度

### 步骤4：下载安装包

构建完成后（约10-15分钟）：

1. 在Actions页面点击最新的工作流运行
2. 在 **Artifacts** 部分下载：
   - 📱 `android-release-apk` - Android安装包
   - 📦 `android-release-aab` - Google Play上传包
   - 🍎 `ios-release-ipa` - iOS安装包（需签名）
   - 🌐 `web-release` - Web版本

---

## 📱 安装到手机

### Android安装

**方式1：直接安装**
1. 下载 `android-release-apk` 中的 `app-release.apk`
2. 发送到手机
3. 点击安装（允许"未知来源"安装）

**方式2：使用ADB**
```bash
# 连接手机，开启USB调试
adb install app-release.apk
```

### iOS安装

**方式1：使用Xcode（开发者）**
1. 下载 `ios-release-ipa`
2. 打开Xcode
3. Window > Devices and Simulators
4. 将IPA拖入设备

**方式2：使用AltStore（非开发者）**
1. 安装 AltStore: https://altstore.io
2. 通过AltStore安装IPA

**方式3：使用TestFlight**
需要配置签名证书

---

## 🔄 持续集成

### 自动触发条件

工作流会在以下情况自动运行：
- ✅ 推送代码到 `main` 或 `master` 分支
- ✅ 创建Pull Request
- ✅ 手动触发（在Actions页面点击"Run workflow"）

### 手动触发构建

1. 打开仓库页面
2. 点击 **Actions** 标签
3. 选择 **Build Flutter App** 工作流
4. 点击 **Run workflow** 按钮
5. 选择分支，点击 **Run workflow**

---

## 📊 构建状态

### 查看构建状态

在仓库首页可以看到构建状态徽章：

```markdown
![Build Status](https://github.com/您的用户名/vision-analyzer/workflows/Build%20Flutter%20App/badge.svg)
```

### 构建任务说明

| 任务 | 说明 | 时间 |
|------|------|------|
| `build-android` | 构建Android APK和AAB | ~5-8分钟 |
| `build-ios` | 构建iOS IPA | ~8-12分钟 |
| `build-web` | 构建Web版本 | ~3-5分钟 |
| `code-quality` | 代码质量检查 | ~2-3分钟 |

---

## 🛠️ 故障排除

### 问题1：构建失败

**解决方案**：
1. 点击失败的构建任务
2. 查看日志输出
3. 修复代码问题
4. 重新推送代码触发构建

### 问题2：找不到Artifacts

**解决方案**：
1. 确保构建成功完成
2. Artifacts可能在构建完成后才显示
3. 刷新页面等待几分钟

### 问题3：APK安装失败

**解决方案**：
1. 确保开启了"允许安装未知来源应用"
2. 检查APK是否完整下载
3. 尝试重新下载

---

## 📦 构建产物说明

### Android

- **app-release.apk** - 可直接安装的APK文件
- **app-release.aab** - Android App Bundle，用于Google Play商店

### iOS

- **app-release.ipa** - iOS应用包（未签名，仅限开发者测试）
- 如需发布，需要配置Apple开发者证书

### Web

- **build/web** - 完整Web应用文件
- 可部署到任何静态网站托管服务

---

## 🎯 下一步

### 发布到应用商店

#### Google Play商店
1. 注册Google Play开发者账号（$25）
2. 使用 `app-release.aab` 文件上传
3. 填写应用信息
4. 提交审核

#### Apple App Store
1. 注册Apple开发者账号（$99/年）
2. 配置签名证书
3. 使用Xcode上传
4. 提交审核

### 部署Web版本

**GitHub Pages（免费）**：
1. 将 `web-release` 中的文件复制到 `gh-pages` 分支
2. 在仓库Settings > Pages中启用
3. 访问 `https://您的用户名.github.io/vision-analyzer`

**Vercel（推荐）**：
1. 注册 https://vercel.com
2. 连接GitHub仓库
3. 自动部署Web版本

---

## 💡 提示

1. **构建时间**：首次构建较慢（下载依赖），后续构建会更快
2. **并行构建**：Android、iOS、Web同时构建，互不影响
3. **代码质量**：每次推送都会自动检查代码质量
4. **免费额度**：GitHub Actions免费额度充足（每月2000分钟）

---

## 📞 需要帮助？

如果遇到问题：
1. 查看GitHub Actions日志
2. 检查代码是否有语法错误
3. 确保所有依赖都正确配置
4. 参考Flutter官方文档：https://flutter.dev
