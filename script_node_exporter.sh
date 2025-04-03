#!/bin/bash
set -e  # Dừng script nếu có lỗi xảy ra

# Hàm xử lý lỗi và in thông báo lỗi cụ thể
trap 'echo "Lỗi xảy ra: $?"' ERR

# Kiểm tra nếu không có tham số
if [ $# -ne 1 ]; then
  echo "Sử dụng: ./script_node_exporter.sh <PORT>"
  exit 1
fi

PORT=$1

# Kiểm tra nếu container với tên node-exporter đã tồn tại
if docker ps -a --format '{{.Names}}' | grep -q "^node-exporter$"; then
  echo "Container node-exporter đã tồn tại. Dừng và xóa container cũ."
  docker rm -f node-exporter
fi

# Chạy Docker container với Node Exporter
docker run -d --name=node-exporter \
  -p $PORT:9100 \
  --restart unless-stopped \
  prom/node-exporter

echo "Node Exporter đã được chạy trên port $PORT"
