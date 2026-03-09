FROM node:22-alpine

# Системные зависимости для работы skills (python скрипты внутри docx/xlsx/pptx skills)
RUN apk add --no-cache \
    python3 \
    py3-pip \
    git \
    bash \
    curl \
  && pip3 install --break-system-packages \
    python-docx \
    openpyxl \
    python-pptx \
    pypdf2

# Устанавливаем OpenCode (пакет называется opencode-ai)
RUN npm install -g opencode-ai

# Создаём нужные директории
RUN mkdir -p \
    /root/.config/opencode \
    /root/.local/share/opencode \
    /root/.claude/skills/docx \
    /root/.claude/skills/xlsx \
    /root/.claude/skills/pptx \
    /root/.claude/skills/pdf \
    /workspace

# Копируем конфиг провайдера (cloud.ru GLM)
COPY opencode.json /root/.config/opencode/opencode.json

# Копируем SKILL.md файлы от Anthropic
COPY skills/docx/SKILL.md /root/.claude/skills/docx/SKILL.md
COPY skills/xlsx/SKILL.md /root/.claude/skills/xlsx/SKILL.md
COPY skills/pptx/SKILL.md /root/.claude/skills/pptx/SKILL.md
COPY skills/pdf/SKILL.md  /root/.claude/skills/pdf/SKILL.md

# Инициализируем пустой git репозиторий (opencode требует git контекст)
WORKDIR /workspace
RUN git init \
  && git config user.email "opencode@service" \
  && git config user.name "opencode"

# Порт HTTP сервера OpenCode
EXPOSE 4096

# Отключаем автообновление
ENV OPENCODE_DISABLE_AUTOUPDATE=true

# API ключ — передаётся через Dokploy Environment, не хранится в образе
ENV CLOUDRU_API_KEY=""

# Пароль для защиты HTTP API (рекомендуется задать в Dokploy Environment)
ENV OPENCODE_SERVER_PASSWORD=""

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD curl -f http://localhost:4096/doc || exit 1

# Запуск как headless HTTP сервер
# 0.0.0.0 — доступен внутри Docker сети (для n8n), но не снаружи
CMD ["opencode", "serve", "--port", "4096", "--hostname", "0.0.0.0"]
