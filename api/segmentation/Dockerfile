# api/segmentation. Build context = the repository root, so the image can copy
# the Kafka JSON Schemas from api/common/contract:
#   docker build -f api/segmentation/Dockerfile .
FROM python:3.12-slim
ENV PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1 CONTRACT_DIR=/app/contract
WORKDIR /app

# System libraries required by mediapipe / opencv at runtime.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 libglib2.0-0 && rm -rf /var/lib/apt/lists/*

COPY api/segmentation/requirements.txt ./
RUN pip install -r requirements.txt

COPY api/segmentation/ ./
COPY api/common/contract/*.schema.json ./contract/
RUN useradd -m -u 10001 appuser && chown -R appuser /app
USER appuser

ENV PORT=8081
EXPOSE 8081
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD python -c "import os,urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:'+os.environ.get('PORT','8081')+'/health').status==200 else 1)"
# No access log: the only routes are the health checks, polled every 30s;
# work happens over Kafka and is logged per message.
CMD ["sh","-c","uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8081} --no-access-log"]
