FROM python:3.11-slim

RUN apt-get update && apt-get install -y curl

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

EXPOSE 8000

# Copy static files to shared volume and start app
CMD ["sh", "-c", "cp -r /app/static/* /var/www/static/ 2>/dev/null || true && python main.py"]