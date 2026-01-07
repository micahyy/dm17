#!/bin/bash
set -e

echo "========================================"
echo "  ZMK 固件构建脚本"
echo "========================================"

# 读取配置文件
if [ -f "build.yaml" ]; then
    echo "使用 build.yaml 配置"
    BOARD=$(grep '^board:' build.yaml | awk '{print $2}' | tr -d '\r')
    SHIELD=$(grep '^shield:' build.yaml | awk '{print $2}' | tr -d '\r')
elif [ -f "build.yml" ]; then
    echo "使用 build.yml 配置"
    BOARD=$(grep '^board:' build.yml | awk '{print $2}' | tr -d '\r')
    SHIELD=$(grep '^shield:' build.yml | awk '{print $2}' | tr -d '\r')
else
    echo "错误：未找到 build.yaml 或 build.yml"
    exit 1
fi

echo "板子: $BOARD"
echo "键盘: $SHIELD"

# 清理旧文件
rm -rf .west build zmk 2>/dev/null || true

# 安装 west（如果不存在）
if ! command -v west &> /dev/null; then
    echo "安装 west..."
    pip3 install west 2>/dev/null || pip install west
fi

# 克隆 ZMK
echo "克隆 ZMK..."
git clone https://github.com/zmkfirmware/zmk.git --depth 1

# 设置 ZMK
cd zmk
west init -l .
west update

# 安装依赖
echo "安装 Python 依赖..."
pip3 install -r zephyr/scripts/requirements.txt

# 构建
echo "构建固件..."
west build -b $BOARD app -- \
    -DSHIELD=$SHIELD \
    -DZMK_CONFIG="../config"

# 返回并复制固件
cd ..
mkdir -p firmware
if [ -f "zmk/build/zephyr/zmk.uf2" ]; then
    cp zmk/build/zephyr/zmk.uf2 firmware/dm17.uf2
    echo "✅ 固件构建成功: firmware/dm17.uf2"
else
    echo "❌ 错误：未生成固件"
    exit 1
fi

echo "========================================"
echo "  构建完成！"
echo "========================================"