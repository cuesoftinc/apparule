FROM python:3.12-slim
ENV PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1
WORKDIR /app

# System libraries required by mediapipe / opencv at runtime.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 libglib2.0-0 && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./
RUN pip install -r requirements.txt

COPY . .
RUN useradd -m -u 10001 appuser && chown -R appuser /app
USER appuser

ENV PORT=8081
EXPOSE 8081
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://localhost:8081/health').status==200 else 1)"
CMD ["sh","-c","uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8081}"]
