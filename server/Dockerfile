FROM postgres:15-bookworm

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV VENV_PATH=/opt/venv

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip \
    supervisor bash ca-certificates \
    build-essential pkg-config \
    libssl-dev libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Create venv + upgrade tooling inside it
RUN python3 -m venv $VENV_PATH \
    && $VENV_PATH/bin/pip install --no-cache-dir --upgrade pip setuptools wheel

WORKDIR /srv

COPY requirements.txt /srv/requirements.txt
RUN $VENV_PATH/bin/pip install --no-cache-dir -r /srv/requirements.txt

COPY app /srv/app
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
COPY entrypoint_api.sh /entrypoint_api.sh
RUN chmod +x /entrypoint.sh /entrypoint_api.sh

EXPOSE 8080
VOLUME ["/data"]

ENTRYPOINT ["/entrypoint.sh"]
