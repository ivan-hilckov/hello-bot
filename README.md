# Hello Bot 👋

Минимальный Telegram бот для тестирования деплоя, основанный на проекте [hello-bot](https://github.com/ivan-hilckov/hello-bot).

## Что делает бот

Отвечает на команду `/start` приветствием "Hello world, ***username***" и на любые другие сообщения предлагает использовать команду `/start`.

## Быстрый старт

1. **Настройка токена бота**:
   ```bash
   cp .env.example .env
   # Отредактируйте .env и добавьте ваш BOT_TOKEN
   ```

2. **Установка зависимостей**:
   ```bash
   make install
   ```

3. **Запуск бота**:
   ```bash
   make run
   ```

4. **Тестирование**: Отправьте `/start` вашему боту в Telegram

## Команды

- `make install` - Установить зависимости
- `make run` - Запустить бота
- `make format` - Отформатировать код
- `make check` - Проверить код линтером
- `make clean` - Очистить кэш файлы

## Требования

- Python 3.11+
- uv (пакетный менеджер)
- Telegram Bot Token от @BotFather

## Переменные окружения

```env
BOT_TOKEN=your_telegram_bot_token_here  # Обязательно
LOG_LEVEL=INFO                          # Опционально
```

## Архитектура

- **Минимальные зависимости**: aiogram + python-dotenv
- **Ресурсы**: ~50MB RAM, ~100MB storage
- **Готов для деплоя**: Docker, systemd, supervisor

## Разработка

Проект использует современные инструменты:
- **uv** для управления зависимостями (10-100x быстрее pip)
- **ruff** для линтинга и форматирования
- **aiogram 3.0+** для Telegram API

## Миграция к полной версии

См. `FORK.md` для инструкций по расширению до полной версии **Hello-Bot** с:
- OpenAI интеграцией
- Управлением резюме
- Генерацией cover letter

## Troubleshooting

1. **Бот не отвечает**: Проверьте корректность BOT_TOKEN
2. **uv не найден**: Установите через `curl -LsSf https://astral.sh/uv/install.sh | sh`
3. **Ошибки импорта**: Выполните `make install`