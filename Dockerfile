FROM node:22-slim AS frontend-build
RUN corepack enable
WORKDIR /app/frontend
COPY frontend/package.json frontend/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY frontend/ ./
RUN pnpm run build

FROM python:3.12-slim
WORKDIR /app/backend
COPY backend/pyproject.toml ./
COPY backend/app ./app
RUN pip install --no-cache-dir .
COPY backend/ ./
RUN python scripts/download_lola.py || true
COPY --from=frontend-build /app/frontend/dist /app/frontend/dist
ENV LUNARPATH_STATIC_DIR=/app/frontend/dist
EXPOSE 8000
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
