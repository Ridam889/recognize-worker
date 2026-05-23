#!/bin/bash
ACTION=$1
AIO_APPS="/var/lib/docker/volumes/nextcloud_aio_nextcloud/_data/custom_apps"
AIO_HTML="/var/lib/docker/volumes/nextcloud_aio_nextcloud/_data"

if [ "$ACTION" == "uninstall" ]; then
    echo "=== [AI Deployer] Starting full uninstallation and cleanup ==="
    systemctl stop nextcloud-ai.service 2>/dev/null
    systemctl disable nextcloud-ai.service 2>/dev/null
    rm -f /etc/systemd/system/nextcloud-ai.service
    systemctl daemon-reload
    rm -rf /tmp/nextcloud-ai/ai-daemon.sh
    if [ -f "$AIO_HTML/occ.original" ]; then
        rm -f "$AIO_HTML/occ" && cp "$AIO_HTML/occ.original" "$AIO_HTML/occ"
        chmod 755 "$AIO_HTML/occ" && chown 33:33 "$AIO_HTML/occ" && rm -f "$AIO_HTML/occ.original"
    fi
    rm -f "$AIO_HTML/occ-bridge.php"
    rm -rf "$AIO_APPS/ai_bridge"
    docker exec --user www-data -w /var/www/html nextcloud-aio-nextcloud php occ app:remove ai_bridge 2>/dev/null
    docker rmi -f nextcloud-ai-recognize-bridge 2>/dev/null
    echo "=== [AI Deployer] System is completely clean now ==="
    exit 0
fi

echo "=== [AI Deployer] Starting automated deployment from GitHub ==="
mkdir -p "$AIO_APPS/ai_bridge/appinfo"
mkdir -p "$AIO_APPS/ai_bridge/lib/BackgroundJob"
mkdir -p "$AIO_APPS/ai_bridge/img"

# 1. Записываем info.xml со встроенным тегом standalone
echo '<?xml version="1.0" standalone="yes"?>
<app>
    <id>ai_bridge</id>
    <name>AI Container Bridge</name>
    <summary>Automated link recovery for external Debian AI worker</summary>
    <description>Maintains host tasks and occ interception script across container restarts.</description>
    <version>1.0.0</version>
    <licence>AGPL</licence>
    <author>Admin</author>
    <namespace>AiBridge</namespace>
    <category>tools</category>
    <standalone />
    <dependencies>
        <nextcloud min-version="31" max-version="31" />
    </dependencies>
</app>' > "$AIO_APPS/ai_bridge/appinfo/info.xml"

# 2. Генерируем векторную SVG-иконку
echo '<svg xmlns="http://w3.org" viewBox="0 0 512 512" width="100%" height="100%"><rect width="512" height="512" rx="128" fill="#0082c9"/><path d="M416 192H320v-32c0-35.3-28.7-64-64-64s-64 28.7-64 64v32H96c-17.7 0-32 14.3-32 32v192c0 17.7 14.3 32 32 32h320c17.7 0 32-14.3 32-32V224c0-17.7-14.3-32-32-32zM224 160c0-17.7 14.3-32 32-32s32 14.3 32 32v32h-64v-32zm160 224H128V256h256v128z" fill="#ffffff"/></svg>' > "$AIO_APPS/ai_bridge/img/app.svg"

# 3. Записываем Application.php
echo '<?php
namespace OCA\AiBridge\AppInfo;
use OCP\AppFramework\App;
class Application extends App {
    public function __construct(array $urlParams = []) { parent::__construct("ai_bridge", $urlParams); }
}' > "$AIO_APPS/ai_bridge/appinfo/Application.php"

# 4. Записываем ClassifyJob.php
echo '<?php
namespace OCA\AiBridge\BackgroundJob;
use OCP\BackgroundJob\TimedJob;
class ClassifyJob extends TimedJob {
    public function __construct() { $this->setInterval(300); }
    protected function run($argument) {
        $trigger = "/var/www/html/recognize.trigger";
        if (!file_exists($trigger)) { @touch($trigger); }
    }
}' > "$AIO_APPS/ai_bridge/lib/BackgroundJob/ClassifyJob.php"

chmod -R 755 "$AIO_APPS/ai_bridge" && chown -R 33:33 "$AIO_APPS/ai_bridge"

# 5. НАКАТЫВАЕМ ИСПРАВЛЕННЫЙ ПЕРЕХВАТЧИК С ЧИСТЫМ PHP КОДОМ (Используем одинарные кавычки для безопасности)
echo '#!/usr/bin/env php
<?php
$args = $_SERVER["argv"];
if (count($args) > 1 && $args === "recognize:classify") {
    $currentTime = date("H:i:s");
    echo "=== [AI Bridge] Intercepted: Request sent to Debian Host ===\n";
    echo "[AI Bridge] Current container time: [$currentTime]. Processing instantly... \n";
    
    $trigger = __DIR__ . "/recognize.trigger";
    $logFile = __DIR__ . "/recognize.log";
    if (file_exists($logFile)) { @unlink($logFile); }
    touch($trigger);
    $lastPos = 0;
    while (file_exists($trigger)) {
        sleep(1);
        if (file_exists($logFile)) {
            clearstatcache(false, $logFile);
            $f = fopen($logFile, "rb");
            if ($f) {
                fseek($f, $lastPos);
                while (($line = fgets($f)) !== false) { echo $line; flush(); }
                $lastPos = ftell($f); fclose($f);
            }
        }
    }
    if (file_exists($logFile)) {
        $f = fopen($logFile, "rb");
        if ($f) { fseek($f, $lastPos); while (($line = fgets($f)) !== false) { echo $line; } fclose($f); @unlink($logFile); }
    }
    echo "=== [AI Bridge] Processing successfully finished ===\n";
} else {
    require_once __DIR__ . "/occ.original";
}' > "$AIO_HTML/occ-bridge.php"

if [ -f "$AIO_HTML/occ" ] && [ ! -f "$AIO_HTML/occ.original" ]; then
    cp "$AIO_HTML/occ" "$AIO_HTML/occ.original"
fi
echo '<?php require_once "/var/www/html/occ-bridge.php";' > "$AIO_HTML/occ"

chmod 755 "$AIO_HTML/occ" "$AIO_HTML/occ-bridge.php"
chown -R 33:33 "$AIO_HTML/occ" "$AIO_HTML/occ-bridge.php" "$AIO_HTML/occ.original"

# Настройка системного демона на хосте
mkdir -p /tmp/nextcloud-ai
cat << 'DAEMON' > /tmp/nextcloud-ai/ai-daemon.sh
#!/bin/bash
TRIGGER="/var/lib/docker/volumes/nextcloud_aio_nextcloud/_data/recognize.trigger"
LOG_FILE="/var/lib/docker/volumes/nextcloud_aio_nextcloud/_data/recognize.log"
while true; do
    if [ -f "$TRIGGER" ]; then
        docker run --rm --cpus="10" --net=nextcloud-aio -v /var/lib/docker/volumes/nextcloud_aio_nextcloud/_data:/var/www/html:rw -v /var/lib/docker/volumes/nextcloud_aio_nextcloud_data/_data:/mnt/ncdata:rw -e EXECUTE_IN_NODE=1 nextcloud-ai-recognize-bridge php /var/www/html/occ.original recognize:classify > "$LOG_FILE" 2>&1
        rm -f "$TRIGGER"
    fi
    sleep 0.5
done
DAEMON
chmod +x /tmp/nextcloud-ai/ai-daemon.sh

cat << 'SERVICE' > /etc/systemd/system/nextcloud-ai.service
[Unit]
Description=Nextcloud AI Recognize Bridge Mgnovenny Daemon
After=docker.service
[Service]
Type=simple
User=root
ExecStart=/tmp/nextcloud-ai/ai-daemon.sh
Restart=always
[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable nextcloud-ai.service 2>/dev/null
systemctl restart nextcloud-ai.service 2>/dev/null

echo "[AI Deployer] Compiling Docker worker image from GitHub..."
docker build https://github.com/Ridam889/nextcloud-ai-recognize-bridge.git -t nextcloud-ai-recognize-bridge
echo "=== [AI Deployer] Automated deployment successfully completed! ==="
