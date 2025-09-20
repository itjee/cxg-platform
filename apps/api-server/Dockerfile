# Multi-stage build for Python FastAPI app
FROM python:3.11-slim as base

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Development stage
FROM base as development

# Copy project files
COPY pyproject.toml uv.lock* ./
COPY src/ ./src/

# Install dependencies
RUN uv sync --frozen || uv pip install --system fastapi uvicorn sqlmodel psycopg2-binary redis pydantic python-multipart pydantic-settings python-jose passlib bcrypt

# Expose port
EXPOSE 8000

# Command for development
CMD ["uv", "run", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

# Production stage
FROM base as production

# Copy project files
COPY pyproject.toml uv.lock* ./
COPY src/ ./src/

# Install dependencies (production only)
RUN uv sync --frozen --no-dev || uv pip install --system fastapi uvicorn sqlmodel psycopg2-binary redis pydantic python-multipart pydantic-settings python-jose passlib bcrypt

# Create non-root user
RUN adduser --disabled-password --gecos '' appuser && chown -R appuser /app
USER appuser

# Expose port
EXPOSE 8000

# Command for production
CMD ["uv", "run", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
