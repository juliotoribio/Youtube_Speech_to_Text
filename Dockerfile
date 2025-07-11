FROM python:3.10-slim

ARG HTTP_PROXY
ARG HTTPS_PROXY

# 0) Deshabilita proxy para APT a nivel de configuración
RUN printf 'Acquire::http::Proxy \"false\";\nAcquire::https::Proxy \"false\";\n' \
    > /etc/apt/apt.conf.d/99no-proxy

WORKDIR /app
COPY . .

# 1) Instala Tor y deps de compilación SIN proxy
RUN apt-get update \
 && apt-get install -y tor libffi-dev python3-dev build-essential \
 && rm -rf /var/lib/apt/lists/*

# 2) Instala tus libs, incluido pysocks
RUN pip install --no-cache-dir -r requirements.txt

# 3) Restaura proxy para el runtime (Tor SOCKS5)
ENV http_proxy=${HTTP_PROXY}
ENV https_proxy=${HTTPS_PROXY}
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}

EXPOSE 5000
CMD service tor start && \
    gunicorn -b 0.0.0.0:$PORT main:app
