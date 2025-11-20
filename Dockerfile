FROM busybox:stable

RUN adduser -D packwiz
USER packwiz
WORKDIR /home/packwiz

COPY . .
CMD ["busybox", "httpd", "-f", "-p", "3000"]

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD ["wget", "http://localhost:3000/pack.toml", "-O", "/dev/null", "-q"]
