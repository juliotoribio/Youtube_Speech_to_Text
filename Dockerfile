# 1) Usa la imagen base de Python
FROM python:3.10-slim

# 2) Sitúa el contexto de trabajo
WORKDIR /app

# 3) Copia todo tu código y requirements
COPY . .

# 4) Deshabilita cualquier proxy en APT para que funcione con SOCKS5
RUN printf 'Acquire::http::Proxy "false";\nAcquire::https::Proxy "false";\n' \
    > /etc/apt/apt.conf.d/99no-proxy

# 5) Instala dependencias del sistema (incluye Tor si lo necesitas en runtime)
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
       tor \
       libffi-dev \
       python3-dev \
       build-essential \
 && rm -rf /var/lib/apt/lists/*

# 6) Instala tus librerías de Python SIN usar proxy en pip
RUN pip install --no-cache-dir --proxy="" -r requirements.txt

# 7) (Opcional) Restaura las variables de proxy para el runtime, si tu app las requiere
ENV HTTP_PROXY="socks5://127.0.0.1:9050"
ENV HTTPS_PROXY="socks5://127.0.0.1:9050"

# 8) Expón el puerto que use tu aplicación (ajusta según tu app)
EXPOSE 3000

# 9) Define comando de arranque (ajusta al entrypoint de tu app)
CMD ["python", "main.py"]
