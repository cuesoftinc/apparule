# api/commerce. Build context = the repository root, so the image can copy
# the Kafka JSON Schemas from api/common/contract:
#   docker build -f api/commerce/Dockerfile .
FROM python:3.12-slim
ENV PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1 CONTRACT_DIR=/app/contract
WORKDIR /app

COPY api/commerce/requirements.txt ./
RUN pip install -r requirements.txt

COPY api/commerce/ ./
COPY api/common/contract/*.schema.json ./contract/
RUN useradd -m -u 10001 appuser && chown -R appuser /app
USER appuser

ENV PORT=8083
EXPOSE 8083
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD python -c "import os,urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:'+os.environ.get('PORT','8083')+'/health').status==200 else 1)"
# No access log: the only routes are the health checks, polled every 30s;
# work happens over Kafka and is logged per message.
CMD ["sh","-c","uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8083} --no-access-log"]
