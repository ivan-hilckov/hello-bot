# Scripts для Hello Bot

## 🚀 deploy_to_vps.sh

**Главный скрипт для настройки VPS** - автоматически копирует и запускает setup_vps.sh на удаленном сервере.

### Использование

```bash
# Запускается локально, настраивает VPS удаленно
./scripts/deploy_to_vps.sh
```

## 🔧 setup_vps.sh

Скрипт настройки VPS сервера (запускается автоматически через deploy_to_vps.sh).

**⚠️ Важно**: Этот скрипт должен запускаться НА VPS СЕРВЕРЕ, а не локально!

### Что делает

- Устанавливает Docker и Docker Compose
- Создает 2GB swap файл для оптимизации памяти
- Настраивает пользователя hello-bot
- Конфигурирует firewall и fail2ban
- Оптимизирует систему для production

## 🧪 test_local.sh

Скрипт для локального тестирования Docker конфигурации.

### Использование

```bash
# Тестирует Docker setup локально
./scripts/test_local.sh
```

## 📊 test_log_vps.sh

Скрипт для анализа VPS сервера перед настройкой GitHub Actions деплоя.

### Использование

```bash
# На VPS сервере (уже выполнено)
./scripts/test_log_vps.sh
```

### Что анализирует

- **Системная информация**: ОС, ядро, архитектура
- **Ресурсы**: CPU, RAM, дисковое пространство
- **Сеть**: внешний IP, DNS, подключение к GitHub
- **Софт**: Docker, Docker Compose, Git, Python
- **Безопасность**: SSH порты, файрвол, SELinux
- **Производительность**: нагрузка, I/O, использование памяти

### Рекомендации

Скрипт автоматически генерирует рекомендации для:

- Выбора стратегии деплоя
- Настройки Docker Compose
- Оптимизации GitHub Actions
- Конфигурации ресурсов

### Пример вывода

```
=== VPS DEPLOYMENT ANALYSIS ===
--- SYSTEM INFO ---
OS: Ubuntu 20.04.6 LTS
CPU Cores: 2
RAM Total: 2G

=== GITHUB ACTIONS RECOMMENDATIONS ===
✅ GOOD RAM (2 GB): Can run multiple services
✅ SUFFICIENT DISK (25 GB): No disk optimizations needed
✅ MULTI CORE (2 cores): Can handle parallel builds

=== DEPLOYMENT STRATEGY ===
✅ FULL DEPLOYMENT: Your VPS can handle the complete setup
```

## 🧪 test_vps.sh

**Финальный тест готовности VPS** к деплою - проверяет все компоненты перед запуском GitHub Actions.

### Использование

```bash
# Копируем скрипт на VPS сервер
scp scripts/test_vps.sh your-user@your-vps-ip:~/

# Подключаемся к VPS и запускаем тест
ssh your-user@your-vps-ip
chmod +x test_vps.sh
./test_vps.sh
```

### Что проверяет

- **Системные ресурсы**: CPU, RAM, диск, swap
- **Сетевое подключение**: интернет, GitHub, Docker Hub, GHCR
- **Docker**: daemon, permissions, compose, функциональность
- **Директории**: права доступа, sudo возможности
- **Безопасность**: SSH, firewall, fail2ban
- **Окружение**: ОС, архитектура, часовой пояс

### Результат

Скрипт выдает детальный отчет о готовности системы:

- ✅ **VPS IS READY** - можно запускать деплой
- ⚠️ **VPS IS MOSTLY READY** - есть предупреждения, но работать будет
- ❌ **VPS NEEDS CONFIGURATION** - требуются исправления

### Связь с деплоем

Этот скрипт должен быть запущен **ПЕРЕД** настройкой GitHub Secrets и запуском деплоя через GitHub Actions.

### init_db.sql

Скрипт инициализации PostgreSQL базы данных.

- Настраивает кодировку UTF8
- Устанавливает часовой пояс UTC
- Логирует успешную инициализацию
