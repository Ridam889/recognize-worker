# 🌉 Nextcloud AI Recognize Bridge

> 🚀 Автоматический AI-мост для Nextcloud 31 AIO с полным AVX2 ускорением

---

## 📦 Быстрая установка

```bash
curl -fsSL https://raw.githubusercontent.com/Ridam889/nextcloud-ai-recognize-bridge/refs/heads/main/core.sh | bash
🗑️ Полное удаление
curl -fsSL https://raw.githubusercontent.com/Ridam889/nextcloud-ai-recognize-bridge/refs/heads/main/core.sh | bash -s uninstall

📋 Требования
Компонент	Версия
Nextcloud AIO	v31+
Docker	24.0+
CPU	AVX2 + FMA
RAM	4 GB

🔧 Устранение проблем
❌ AVX2 не найден	     - grep avx2 /proc/cpuinfo
🐳 Docker ошибка	         - systemctl restart docker
🔒 Нет доступа к Docker	 - sudo usermod -aG docker $USER
💀 Контейнер не стартует	 - docker logs nextcloud-ai-recognize-bridge
📦 Где контейнер     	 - docker images | grep nextcloud-ai-recognize-bridge

📄 Лицензия

MIT © Ridam Sobuz


⭐ Поставьте звезду на GitHub, если проект вам полезен!
