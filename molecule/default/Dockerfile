FROM docker.io/ubuntu:noble

RUN apt-get update && apt-get install -y python3 systemd iproute2

ENTRYPOINT ["/lib/systemd/systemd"]
