FROM python:3.10-slim

WORKDIR /app
COPY . .

# 1) Deshabilita proxy para APT
RUN printf 'Acquire::http::Proxy "false";\nAcquire::https::Proxy "false";\n' \
    > /etc/apt/apt.conf.d/99no-proxy

# 2) Instala dependencias de sistema
RUN apt-get update \
 && apt-get install -y tor libffi-dev python3-dev build-essential \
 && rm -rf /var/lib/apt/lists/*

# 3) Deshabilita proxy de entorno para pip e instala tus librerías
RUN HTTP_PROXY="" HTTPS_PROXY="" \
    pip install --no-cache-dir -r requirements.txt

# 4) (Opcional) Vuelve a restaurar proxy para el runtime, si lo necesitas
ENV HTTP_PROXY="socks5://127.0.0.1:9050" \
    HTTPS_PROXY="socks5://127.0.0.1:9050"
