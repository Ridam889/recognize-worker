FROM node:20-bookworm-slim

RUN apt update && apt install -y \
    build-essential python3 php-cli php-curl php-gd \
    php-mbstring php-xml php-zip php-pgsql php-mysql php-redis \
    ffmpeg && \
    npm install -g node-pre-gyp node-gyp && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

RUN ln -s /usr/local/bin/node /usr/bin/node 2>/dev/null || true && \
    mkdir -p /bin && ln -s /usr/bin/nice /bin/nice 2>/dev/null || true

CMD ["php", "occ", "recognize:classify"]
