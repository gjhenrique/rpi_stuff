FROM docker.io/ubuntu:focal

RUN apt-get update && apt-get install -y python3 systemd iproute2

ENTRYPOINT ["/lib/systemd/systemd"]
