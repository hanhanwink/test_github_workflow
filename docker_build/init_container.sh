#!/bin/bash

echo "Step 0"
echo "尝试去SSM获取env配置"
if [ -n "$SSM_PARAMETER_NAME" ] && [ -n "$AWS_REGION" ]; then
    aws ssm get-parameter --name "$SSM_PARAMETER_NAME" --with-decryption --query "Parameter.Value" --output text --region "$AWS_REGION" > /app/.env
    if [ $? -eq 0 ] && [ -s "/app/.env" ]; then
        echo "Step 0：配置已从SSM成功下载到 /app/.env"
    else
        echo "Step 0：从 SSM 下载配置失败，请检查参数名称、区域和 IAM 权限。" >&2
        exit 1
    fi
fi

echo "Step 1"
echo "Running migrations..."
php artisan migrate --isolated --force

echo "Step 2"
echo "Step 2：启动php项目"
php-fpm -D
cron
echo "=================================================="

echo "Step 3"
echo "Step 3：启动supervisord和nginx服务"
supervisord -c /etc/supervisor/supervisord.conf &
echo "=================================================="

echo "Step 4"
echo "Step 4：Stdout Access Logs..."
tail -f /var/log/nginx/json_access.log
