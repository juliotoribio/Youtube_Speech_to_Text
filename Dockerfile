FROM python:3.10-slim

WORKDIR /app
COPY . .

# 1) Deshabilita proxy APT para apt-get
RUN printf 'Acquire::http::Proxy "false";\nAcquire::https::Proxy "false";\n' \
    > /etc/apt/apt.conf.d/99no-proxy

# 2) Instala deps de sistema (incluye libffi para PySocks)
RUN apt-get update \
 && apt-get install -y tor libffi-dev python3-dev build-essential \
 && rm -rf /var/lib/apt/lists/*

# 3) Limpia las vars de proxy para pip
ENV HTTP_PROXY=""
ENV HTTPS_PROXY=""

# 4) Instala tus librerías de Python
RUN pip install --no-cache-dir -r requirements.txt

# 5) (Opcional) Vuelve a restaurar proxy para el runtime, si lo necesitas para Tor
ENV HTTP_PROXY="socks5://127.0.0.1:9050"
ENV HTTPS_PROXY="socks5://127.0.0.1:9050"

CMD ["python", "main.py"]
