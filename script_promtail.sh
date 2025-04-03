#!/bin/bash

# Kiểm tra nếu không đủ tham số
if [ $# -ne 3 ]; then
  echo "Sử dụng: ./file.sh <PORT> <JOB_NAME> <LOG_PATH>"
  echo "Ví dụ: ./file.sh 9090 namelogs /var/log/*.log"
  exit 1
fi

PORT=$1
JOB_NAME=$2
LOG_PATH=$3

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

# Chạy container Promtail với cấu hình động
docker run -d --name=promtail \
  -p $PORT:9080 \
  -v $(pwd)/promtail-config.yml:/etc/promtail/promtail-config.yml \
  grafana/promtail -config.file=/etc/promtail/promtail-config.yml

echo "Promtail đã được chạy trên port $PORT với job_name=$JOB_NAME và log_path=$LOG_PATH"
