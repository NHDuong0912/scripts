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
  rm -rf $HOME/promtail-config.yml
fi

# Tạo file cấu hình promtail
cat > promtail-config.yml <<EOL
server:
  http_listen_address: 0.0.0.0
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://113.23.120.100:3100/loki/api/v1/push

scrape_configs:
  - job_name: "$JOB_NAME"
    static_configs:
      - targets:
          - localhost
        labels:
          job: "$JOB_NAME"
          service: "logs_node"
          __path__: /logs/$(basename $LOG_PATH)
EOL

LOG_DIR=$(dirname "$LOG_PATH")

# Kiểm tra xem thư mục chứa file log có tồn tại không, nếu không sẽ tạo thư mục đó
if [ ! -d "$LOG_DIR" ]; then
  echo "Thư mục chứa file log không tồn tại. Tạo thư mục $LOG_DIR."
  mkdir -p "$LOG_DIR"
fi

# Chạy Docker container Promtail với cấu hình động
docker run -d --name=promtail \
  -p $PORT:9080 \
  -v $LOG_DIR:/logs \
  -v $(pwd)/promtail-config.yml:/etc/promtail/promtail-config.yml \
  grafana/promtail -config.file=/etc/promtail/promtail-config.yml

echo "Promtail đã được chạy trên port $PORT với job_name=$JOB_NAME và log_path=$LOG_PATH"
