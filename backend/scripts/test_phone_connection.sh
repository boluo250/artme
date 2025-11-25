#!/bin/bash

# 测试真机连接脚本
# 用于验证 Mac 后端服务是否可以被手机访问

echo "🔍 检查后端服务连接..."
echo ""

# 获取 Mac IP 地址
MAC_IP=$(ipconfig getifaddr en0 2>/dev/null || ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')

if [ -z "$MAC_IP" ]; then
    echo "❌ 无法获取 Mac IP 地址"
    exit 1
fi

echo "📱 Mac IP 地址: $MAC_IP"
echo ""

# 测试本地连接
echo "1️⃣ 测试本地连接 (localhost:8000)..."
LOCAL_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null)
if [ "$LOCAL_RESPONSE" = "200" ]; then
    echo "   ✅ 本地连接正常"
else
    echo "   ❌ 本地连接失败 (HTTP $LOCAL_RESPONSE)"
    echo "   💡 请确保后端服务正在运行:"
    echo "      python -m uvicorn app.main:app --host 0.0.0.0 --port 8000"
    exit 1
fi

echo ""

# 测试 IP 连接
echo "2️⃣ 测试 IP 连接 ($MAC_IP:8000)..."
IP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://$MAC_IP:8000/health 2>/dev/null)
if [ "$IP_RESPONSE" = "200" ]; then
    echo "   ✅ IP 连接正常"
else
    echo "   ❌ IP 连接失败 (HTTP $IP_RESPONSE)"
    echo "   💡 请检查后端服务是否绑定到 0.0.0.0"
    exit 1
fi

echo ""

# 测试 API 端点
echo "3️⃣ 测试 API 端点..."
API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://$MAC_IP:8000/api/v1/prompts/list 2>/dev/null)
if [ "$API_RESPONSE" = "200" ]; then
    echo "   ✅ API 端点正常"
else
    echo "   ⚠️  API 端点返回 HTTP $API_RESPONSE"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 连接测试完成！"
echo ""
echo "📱 在 iPhone 上测试："
echo "   1. 确保 iPhone 和 Mac 在同一 Wi-Fi 网络"
echo "   2. 在 Safari 中访问: http://$MAC_IP:8000/api/v1/prompts/list"
echo "   3. 如果能看到 JSON 数据，说明连接正常"
echo ""
echo "🔧 iOS 应用配置："
echo "   在 Constants.swift 中，真机应该使用:"
echo "   static let apiBaseURL = \"http://$MAC_IP:8000\""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"




