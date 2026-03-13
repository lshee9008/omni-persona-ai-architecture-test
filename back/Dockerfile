FROM python:3.11-slim

WORKDIR /app

# FAISS 실행에 필요한 패키지 설치
RUN apt-get update && apt-get install -y libomp-dev

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]