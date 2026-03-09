FROM node:22-alpine

# Системные зависимости
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
    pypdf2 \
    lxml

# Устанавливаем OpenCode (пакет называется opencode-ai)
RUN npm install -g opencode-ai

# Создаём нужные директории
RUN mkdir -p \
    /root/.config/opencode \
    /root/.local/share/opencode \
    /root/.claude/skills \
    /workspace

# Клонируем skills от Anthropic напрямую из их репозитория
# Берём только нужные папки (docx, xlsx, pptx, pdf) через sparse-checkout
RUN git clone --depth=1 --filter=blob:none --sparse \
    https://github.com/anthropics/skills.git /tmp/anthropic-skills \
  && cd /tmp/anthropic-skills \
  && git sparse-checkout set skills/docx skills/xlsx skills/pptx skills/pdf \
  && cp -r skills/docx /root/.claude/skills/docx \
  && cp -r skills/xlsx /root/.claude/skills/xlsx \
  && cp -r skills/pptx /root/.claude/skills/pptx \
  && cp -r skills/pdf  /root/.claude/skills/pdf \
  && rm -rf /tmp/anthropic-skills

# Копируем конфиг провайдера (cloud.ru GLM)
COPY opencode.json /root/.config/opencode/opencode.json

# Инициализируем пустой git репозиторий
# (opencode требует git контекст для поиска skills)
WORKDIR /workspace
RUN git init \
  && git config user.email "opencode@service" \
  && git config user.name "opencode"

EXPOSE 4096

ENV OPENCODE_DISABLE_AUTOUPDATE=true
ENV CLOUDRU_API_KEY=""
ENV OPENCODE_SERVER_PASSWORD=""

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD curl -f http://localhost:4096/doc || exit 1

# Запуск как headless HTTP сервер, доступный внутри Docker сети
CMD ["opencode", "serve", "--port", "4096", "--hostname", "0.0.0.0"]
