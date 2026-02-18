#!/bin/bash
# 测试执行脚本
# 使用方法: ./run_tests.sh

echo "========================================"
echo "视功能分析App - 测试执行脚本"
echo "========================================"
echo ""

# 检查Flutter环境
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter未安装或未添加到PATH"
    echo "请先安装Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter环境检测通过"
echo "Flutter版本: $(flutter --version | head -1)"
echo ""

# 获取依赖
echo "📦 获取依赖..."
flutter pub get

# 运行所有测试
echo ""
echo "🧪 运行所有测试..."
flutter test

# 生成覆盖率报告
echo ""
echo "📊 生成覆盖率报告..."
flutter test --coverage

# 检查lcov是否安装
if command -v lcov &> /dev/null; then
    echo "📝 生成HTML覆盖率报告..."
    genhtml coverage/lcov.info -o coverage/html
    echo "✅ 覆盖率报告已生成: coverage/html/index.html"
else
    echo "⚠️  lcov未安装，跳过HTML报告生成"
    echo "   覆盖率数据已保存: coverage/lcov.info"
fi

echo ""
echo "========================================"
echo "测试执行完成!"
echo "========================================"
