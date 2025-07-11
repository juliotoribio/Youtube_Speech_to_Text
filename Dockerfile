FROM python:3.10-slim

# 1) Declaramos args para que Docker no marque error al recibir build-args
ARG HTTP_PROXY
ARG HTTPS_PROXY

WORKDIR /app
COPY . .

# 2) Instalamos Tor (para runtime) y deps de sistema si necesitas compilar algo
RUN apt-get update && \
    apt-get install -y tor libffi-dev python3-dev build-essential && \
    rm -rf /var/lib/apt/lists/*

# 3) Desactivamos proxy sólo para la instalación de requirements
ENV HTTP_PROXY=""
ENV HTTPS_PROXY=""
RUN pip install --no-cache-dir -r requirements.txt

# 4) Restauramos proxy para el runtime (EasyPanel inyectará las vars aquí)
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}

# 5) Exponemos el puerto y arrancamos Tor + Gunicorn
EXPOSE 5000
CMD service tor start && \
    gunicorn -b 0.0.0.0:$PORT main:app
