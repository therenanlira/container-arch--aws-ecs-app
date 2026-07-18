FROM fidelissauro/apko-go:latest-amd64 AS builder

WORKDIR /root/src/app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

FROM fidelissauro/apko-run:latest-amd64

COPY --from=builder /root/src/app/main ./
EXPOSE 8080
ENTRYPOINT ["./main"]
