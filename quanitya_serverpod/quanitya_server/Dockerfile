# Build stage
FROM dart:3.10.4 AS build
WORKDIR /app
COPY . .

RUN dart pub get
RUN dart compile exe bin/main.dart -o bin/server

# Final stage
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates curl && rm -rf /var/lib/apt/lists/*

RUN useradd -r -s /bin/false -m -d /app quanitya
WORKDIR /app

COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/server
COPY --from=build /app/config/ /app/config/
COPY --from=build /app/web/ /app/web/
COPY --from=build /app/migrations/ /app/migrations/
COPY --from=build /app/lib/src/generated/protocol.yaml /app/lib/src/generated/protocol.yaml

RUN chown -R quanitya:quanitya /app
USER quanitya

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

EXPOSE 8080 8081 8082

ENTRYPOINT ["/app/server", "--mode", "production"]
