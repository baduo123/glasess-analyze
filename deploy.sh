#!/bin/bash

echo "🚀 GitHub Actions 自动打包部署脚本"
echo "=================================="
echo ""

# 检查是否在正确的目录
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ 错误：请在项目根目录运行此脚本"
    exit 1
fi

# 获取GitHub用户名
echo "请输入您的GitHub用户名："
read USERNAME

if [ -z "$USERNAME" ]; then
    echo "❌ 错误：用户名不能为空"
    exit 1
fi

# 配置远程仓库
echo ""
echo "步骤1: 配置GitHub远程仓库..."
git remote remove origin 2>/dev/null
git remote add origin "https://github.com/$USERNAME/vision-analyzer.git"
echo "✅ 远程仓库配置完成"

# 提交所有更改
echo ""
echo "步骤2: 提交代码更改..."
git add -A
git commit -m "Add GitHub Actions workflow for automatic builds" || echo "没有新更改需要提交"
echo "✅ 代码提交完成"

# 推送到GitHub
echo ""
echo "步骤3: 推送到GitHub..."
echo "⚠️  如果提示输入密码，请使用Personal Access Token"
git push -u origin main
echo "✅ 代码推送完成"

echo ""
echo "=================================="
echo "✅ 部署完成！"
echo ""
echo "下一步："
echo "1. 访问: https://github.com/$USERNAME/vision-analyzer/actions"
echo "2. 等待构建完成（约10-15分钟）"
echo "3. 下载Artifacts中的APK/IPA文件"
echo ""
echo "📱 首次使用请先创建GitHub仓库："
echo "   https://github.com/new"
echo "   仓库名: vision-analyzer"
echo ""
