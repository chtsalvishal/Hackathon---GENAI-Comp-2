FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

ENV PORT=8080
ENV PYTHONUNBUFFERED=1

# Use gunicorn with a single worker — processing is async-within-process,
# not multi-process. Timeout set to 1800s to cover large customer batches.
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "1", \
     "--timeout", "1800", "--log-level", "info", "main:app"]
