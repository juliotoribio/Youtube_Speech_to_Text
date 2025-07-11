FROM python:3.10-slim

# Recibe los build-args de proxy (pero no los expone en ENV todavía)
ARG HTTP_PROXY
ARG HTTPS_PROXY

# 1) Desactiva cualquier proxy HTTP/S para apt-get y pip install
ENV http_proxy=""
ENV https_proxy=""
ENV HTTP_PROXY=""
ENV HTTPS_PROXY=""

WORKDIR /app
COPY . .

# 2) Evita proxy en APT usando configuración
RUN printf 'Acquire::http::Proxy "false";\nAcquire::https::Proxy "false";\n' \
    > /etc/apt/apt.conf.d/99no-proxy

# 3) Instala Tor y dependencias del sistema sin proxy
RUN apt-get update \
 && apt-get install -y tor libffi-dev python3-dev build-essential \
 && rm -rf /var/lib/apt/lists/*

# 4) Instala paquetes de Python (incluye pysocks) sin proxy
RUN pip install --no-cache-dir -r requirements.txt

# 5) Restaura las vars de proxy para el runtime (Tor SOCKS5)
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
ENV http_proxy=${HTTP_PROXY}
ENV https_proxy=${HTTPS_PROXY}

# 6) Expone el puerto y arranca Tor + Gunicorn
EXPOSE 5000
CMD service tor start && \
    gunicorn -b 0.0.0.0:$PORT main:app
