#!/bin/bash
set -e

echo "========================================"
echo "  DM17 固件构建脚本"
echo "========================================"

# 读取配置
if [ -f "build.yaml" ]; then
    BOARD=$(grep '^board:' build.yaml | awk '{print $2}')
    SHIELD=$(grep '^shield:' build.yaml | awk '{print $2}')
elif [ -f "build.yml" ]; then
    BOARD=$(grep '^board:' build.yml | awk '{print $2}')
    SHIELD=$(grep '^shield:' build.yml | awk '{print $2}')
else
    BOARD="nrf52840dk_nrf52840"
    SHIELD="dm17"
fi

echo "板子: $BOARD"
echo "键盘: $SHIELD"

# 清理
rm -rf .west build zmk firmware 2>/dev/null || true

# 安装 west
echo "安装 west..."
pip3 install west >/dev/null 2>&1 || pip install west

# 克隆 ZMK
echo "克隆 ZMK..."
git clone https://github.com/zmkfirmware/zmk.git --depth 1

# 设置
cd zmk
west init -l .
west update

echo "安装依赖..."
pip3 install -r zephyr/scripts/requirements.txt

# 构建
echo "构建固件..."
west build -b $BOARD app -- \
    -DSHIELD=$SHIELD \
    -DZMK_CONFIG="../config"

# 返回到仓库根目录
cd ..

# 创建 firmware 目录并复制固件
echo "复制固件..."
mkdir -p firmware

# 尝试从多个位置复制
if [ -f "zmk/build/zephyr/zmk.uf2" ]; then
    cp zmk/build/zephyr/zmk.uf2 firmware/dm17.uf2
    echo "✅ 从 zmk/build/zephyr/ 复制固件"
elif [ -f "build/zephyr/zmk.uf2" ]; then
    cp build/zephyr/zmk.uf2 firmware/dm17.uf2
    echo "✅ 从 build/zephyr/ 复制固件"
else
    # 查找所有 .uf2 文件
    find . -name "*.uf2" -exec cp {} firmware/ \; 2>/dev/null || true
    if [ -f "firmware/zmk.uf2" ]; then
        mv firmware/zmk.uf2 firmware/dm17.uf2
        echo "✅ 找到并重命名固件"
    fi
fi

# 检查结果
echo "固件目录内容:"
ls -la firmware/ 2>/dev/null || echo "firmware 目录为空"

if [ -f "firmware/dm17.uf2" ]; then
    echo "✅ 固件构建成功: firmware/dm17.uf2"
    echo "文件大小: $(stat -c%s firmware/dm17.uf2) 字节"
else
    echo "❌ 错误：未生成固件文件"
    echo "查找所有 .uf2 文件:"
    find . -name "*.uf2" 2>/dev/null || echo "没有找到任何 .uf2 文件"
    exit 1
fi

echo "========================================"
echo "  构建完成！"
echo "========================================"