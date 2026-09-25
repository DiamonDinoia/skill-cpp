FROM node:22-bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends git python3 ca-certificates \
 && rm -rf /var/lib/apt/lists/*
ARG GH=2.101.0
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/* \
 && curl -fsSL "https://github.com/cli/cli/releases/download/v${GH}/gh_${GH}_linux_amd64.tar.gz" \
  | tar -xz -C /usr/local --strip-components=1
RUN npm install -g @anthropic-ai/claude-code @openai/codex @google/gemini-cli opencode-ai skills
RUN useradd -m u
USER u
WORKDIR /home/u
