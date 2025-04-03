#!/bin/bash

# Kiểm tra nếu không có tham số
if [ -z "$1" ]; then
  echo "Vui lòng cung cấp port. Ví dụ: ./file.sh 9000"
  exit 1
fi

PORT=$1

# Chạy container Docker với port do người dùng nhập vào
docker run -d --name=node-exporter \
  -p $PORT:9100 \
  --restart unless-stopped \
  prom/node-exporter

echo "Node Exporter đã được chạy trên port $PORT"
