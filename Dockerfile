# 1) Base
FROM python:3.10-slim

# 2) Directorio de trabajo
WORKDIR /app

# 3) Copia el código y requisitos
COPY . .

# 4) Deshabilita proxy para APT e instala paquetes de sistema
RUN printf 'Acquire::http::Proxy "false";\nAcquire::https::Proxy "false";\n' \
      > /etc/apt/apt.conf.d/99no-proxy \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
       tor \
       libffi-dev \
       python3-dev \
       build-essential \
 && rm -rf /var/lib/apt/lists/*

# 5) Pip SIN proxy
ENV HTTP_PROXY="" \
    HTTPS_PROXY=""
RUN pip install --no-cache-dir -r requirements.txt

# 6) Restaura proxy para runtime (usa los mismos valores de build-args)
ARG HTTP_PROXY
ARG HTTPS_PROXY
ENV HTTP_PROXY=${HTTP_PROXY} \
    HTTPS_PROXY=${HTTPS_PROXY}

# 7) Arranca Tor y luego tu aplicación
CMD tor & \
    python main.py
