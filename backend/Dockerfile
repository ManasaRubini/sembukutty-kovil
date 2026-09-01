# Production Dockerfile for FastAPI Cloud Deployment (Render.com / Koyeb / Railway)
FROM python:3.12-slim

WORKDIR /app

# Install system dependencies for PostgreSQL
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements & install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application backend code
COPY . .

# Expose port (Render automatically sets PORT env var)
ENV PORT=8000
EXPOSE 8000

# Start Uvicorn production server
CMD uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}
