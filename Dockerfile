FROM alpine:3.19
RUN apk add --no-cache curl unzip bash gcompat ca-certificates
RUN curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
ENV PATH="/root/.rokit/bin:${PATH}"
RUN rokit add lune --global
WORKDIR /app
COPY . .
EXPOSE 8080
CMD ["lune", "run", "server.luau"]
