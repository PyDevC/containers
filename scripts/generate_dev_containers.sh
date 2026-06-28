#!/usr/bin/env bash

DISTRO="${1:-}"
BASE_NAME="base${DISTRO}"
NEW_USER="pydevc"
DEFAULT_PASS="12345678" # Change your password inside the container

if [[ -z "$DISTRO" ]] || [[ "$DISTRO" != "fedora" && "$DISTRO" != "ubuntu" ]]; then
    echo "Error: Missing or invalid argument."
    echo "Usage: $0 [fedora|ubuntu]"
    exit 1
fi

create_base_fedora() {
    local container="basefedora"
    podman run -d --name "$container" fedora:42 sleep infinity

    podman exec "$container" useradd -m "$NEW_USER"
    podman exec "$container" sh -c "echo '$NEW_USER:$DEFAULT_PASS' | chpasswd"
    
    podman exec "$container" sh -c "dnf update -y && dnf install -y sudo"
    podman exec "$container" usermod -aG wheel "$NEW_USER"
    podman exec "$container" groups "$NEW_USER"

    podman commit "$container" "$container"
    podman rm -f "$container"
}

create_base_ubuntu() {
    local container="baseubuntu"
    podman run -d --name "$container" ubuntu sleep infinity

    podman exec "$container" userdel -r ubuntu || true 
    podman exec "$container" useradd -u 1000 -m -s /bin/bash "$NEW_USER"
    podman exec "$container" sh -c "echo '$NEW_USER:$DEFAULT_PASS' | chpasswd"
    
    podman exec "$container" sh -c "apt-get update && apt-get install -y sudo"
    podman exec "$container" usermod -aG sudo "$NEW_USER"
    podman exec "$container" groups "$NEW_USER"

    podman commit "$container" "$container"
    podman rm -f "$container"
}

echo "Building $BASE_NAME ...."

case "$BASE_NAME" in
    "baseubuntu")
        create_base_ubuntu
        ;;
    "basefedora")
        create_base_fedora
        ;;
esac

echo "Successfully built $BASE_NAME!"
