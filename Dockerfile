FROM node:22-slim AS frontend-build
RUN corepack enable
WORKDIR /app/frontend
COPY frontend/package.json frontend/pnpm-lock.yaml frontend/pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile
COPY frontend/ ./
ENV NODE_OPTIONS="--max-old-space-size=512"
RUN pnpm run build

FROM python:3.12-slim
WORKDIR /app/backend
# Copy frontend build first so BuildKit runs Node and pip sequentially (avoids OOM exit 137).
COPY --from=frontend-build /app/frontend/dist /app/frontend/dist
RUN pip install --no-cache-dir "fastapi>=0.118,<1" "httpx>=0.27,<1" "uvicorn>=0.30,<1" "python-dotenv>=1,<2" "pillow>=11,<13"
COPY backend/ ./
RUN python scripts/download_lola.py || true
ENV LUNARPATH_STATIC_DIR=/app/frontend/dist
EXPOSE 8000
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
