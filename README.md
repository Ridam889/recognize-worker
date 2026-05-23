# 🌉 Nextcloud AI Recognize Bridge

> 🚀 **Автоматический AI-мост** для Nextcloud 31 AIO с полным **AVX2** ускорением и защитой от потери хуков после обновлений

![License](https://img.shields.io/badge/License-MIT-yellow.svg)
![Docker](https://img.shields.io/badge/Docker-24.0+-2496ED?logo=docker)
![Nextcloud](https://img.shields.io/badge/Nextcloud-31+-0082C9?logo=nextcloud)
![AVX2](https://img.shields.io/badge/AVX2-FMA-supported-brightgreen)

---

## ✨ Возможности
- **Полное AVX2 + FMA ускорение** для моделей `recognize`
- **Автоматическое восстановление хуков** после обновления Nextcloud AIO
- **Лёгкая установка в один скрипт**
- **Автообновление** Docker-образа
- **Минимальное потребление ресурсов**
- **Поддержка CPU-only** окружений с максимальной производительностью
- Защита от потери распознавания лиц/объектов после обновлений

---

## 📦Установка / удаление
```bash
# Установка / обновление
curl -fsSL https://raw.githubusercontent.com/Ridam889/nextcloud-ai-recognize-bridge/main/core.sh | bash
```
```
# Полное удаление
curl -fsSL https://raw.githubusercontent.com/Ridam889/nextcloud-ai-recognize-bridge/main/core.sh | bash -s uninstall
```

---

## 📋 Требования
| Компонент | Требование |
| :--- | :--- |
| Nextcloud AIO | v31+ |
| Docker | 24.0+ |
| CPU | AVX2 + FMA |
| RAM | минимум 4 ГБ |

---

## 🔧 Устранение проблем
| Проблема | Решение |
| :--- | :--- |
| ❌ AVX2 не найден | grep avx2 /proc/cpuinfo |
| 🐳 Ошибки Docker | systemctl restart docker |
| 🔒 Нет доступа к Docker | sudo usermod -aG docker $USER |
| 💀 Контейнер не запускается | docker logs nextcloud-ai-recognize-bridge |
| 📸 Проверить поддержку iGPU | ls -l /dev/drils -l /dev/drils -l /dev/dri |

---

⭐ Поддержка проекта
Если проект тебе помог — поставь звезду на GitHub! ❤️
Made with ❤️ for Nextcloud Community

📄 Лицензия
MIT License © Ridam Sobuz