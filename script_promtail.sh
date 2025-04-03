#!/bin/bash
set -e  # Dừng script nếu có lỗi xảy ra

# Hàm xử lý lỗi và in thông báo lỗi cụ thể
trap 'echo "Lỗi xảy ra: $?"' ERR

# Kiểm tra số lượng tham số
if [ $# -ne 3 ]; then
  echo "Sử dụng: ./script_promtail.sh <PORT> <JOB_NAME> <LOG_PATH>"
  exit 1
fi

PORT=$1
JOB_NAME=$2
LOG_PATH=$3

# Kiểm tra nếu container với tên promtail đã tồn tại
if docker ps -a --format '{{.Names}}' | grep -q "^promtail$"; then
  echo "Container promtail đã tồn tại. Dừng và xóa container cũ."
  docker rm -f promtail
fi

# Tạo file cấu hình promtail
cat > promtail-config.yml <<EOL
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://<loki>:3100/loki/api/v1/push

scrape_configs:
  - job_name: "$JOB_NAME"
    static_configs:
      - targets:
          - localhost
        labels:
          job: "varlogs"
          __path__: $LOG_PATH
EOL

# Chạy Docker container Promtail với cấu hình động
docker run -d --name=promtail \
  -p $PORT:9080 \
  -v $(pwd)/promtail-config.yml:/etc/promtail/promtail-config.yml \
  grafana/promtail -config.file=/etc/promtail/promtail-config.yml

echo "Promtail đã được chạy trên port $PORT với job_name=$JOB_NAME và log_path=$LOG_PATH"
