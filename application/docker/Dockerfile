FROM cgr.dev/chainguard/node:latest

WORKDIR /app

COPY --chown=nonroot:nonroot package.json ./
COPY --chown=nonroot:nonroot server.js healthcheck.js ./

USER nonroot

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 CMD ["node", "healthcheck.js"]

CMD ["node", "server.js"]

