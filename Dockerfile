FROM node:22-slim

# Системные зависимости (Debian-based, совместим с opencode-ai бинарником)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    git \
    bash \
    curl \
  && python3 -m venv /opt/venv \
  && /opt/venv/bin/pip install \
    python-docx \
    openpyxl \
    python-pptx \
    pypdf2 \
    lxml \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ENV PATH="/opt/venv/bin:$PATH"

# Устанавливаем OpenCode
RUN npm install -g opencode-ai

# Создаём нужные директории
RUN mkdir -p \
    /root/.config/opencode \
    /root/.local/share/opencode \
    /root/.claude/skills \
    /workspace

# Клонируем skills от Anthropic
RUN git clone --depth=1 --filter=blob:none --sparse \
    https://github.com/anthropics/skills.git /tmp/anthropic-skills \
  && cd /tmp/anthropic-skills \
  && git sparse-checkout set skills/docx skills/xlsx skills/pptx skills/pdf \
  && cp -r skills/docx /root/.claude/skills/docx \
  && cp -r skills/xlsx /root/.claude/skills/xlsx \
  && cp -r skills/pptx /root/.claude/skills/pptx \
  && cp -r skills/pdf  /root/.claude/skills/pdf \
  && rm -rf /tmp/anthropic-skills

# Копируем конфиг провайдера
COPY opencode.json /root/.config/opencode/opencode.json

# Инициализируем git репозиторий (opencode требует git контекст)
WORKDIR /workspace
RUN git init \
  && git config user.email "opencode@service" \
  && git config user.name "opencode"

EXPOSE 4096

ENV OPENCODE_DISABLE_AUTOUPDATE=true
ENV CLOUDRU_API_KEY=""
ENV OPENCODE_SERVER_PASSWORD=""

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD wget -q -O- http://localhost:4096/session || exit 1

CMD ["opencode", "serve", "--port", "4096", "--hostname", "0.0.0.0"]
