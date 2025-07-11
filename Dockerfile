FROM python:3.10-slim

# 1) Recibimos los build-args (con proxy), pero no los exportamos como ENV aún
ARG HTTP_PROXY
ARG HTTPS_PROXY

# 2) Desactivamos por completo cualquier proxy para las instalaciones
#     (APT y pip usarán conexión directa)
ENV http_proxy=""
ENV https_proxy=""
ENV HTTP_PROXY=""
ENV HTTPS_PROXY=""

WORKDIR /app
COPY . .

# 3) Instalación de Tor y deps de sistema
RUN apt-get update && \
    apt-get install -y tor libffi-dev python3-dev build-essential && \
    rm -rf /var/lib/apt/lists/*

# 4) Instalación de requirements (incluye pysocks)
RUN pip install --no-cache-dir -r requirements.txt

# 5) Restauramos las vars de proxy para el runtime
ENV http_proxy=${HTTP_PROXY}
ENV https_proxy=${HTTPS_PROXY}
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}

# 6) Exponemos y arrancamos
EXPOSE 5000
CMD service tor start && \
    gunicorn -b 0.0.0.0:$PORT main:app
