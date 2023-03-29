FROM docker.io/manjarolinux/base

RUN yes | pacman -Sy python systemd iproute2

ENTRYPOINT ["/lib/systemd/systemd"]
