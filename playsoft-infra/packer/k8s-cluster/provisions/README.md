# Kubernetes Node Setup Script

This script automates the preparation of a Linux machine to become a Kubernetes node using `kubeadm`. It installs and configures all required components, including the container runtime and system-level dependencies.

---

## Overview

The script performs the following tasks:

- Disables swap (required by Kubernetes)
- Installs system dependencies
- Adds the Kubernetes APT repository (version-controlled)
- Installs:
  - `containerd` (container runtime)
  - `kubelet` (node agent)
  - `kubeadm` (cluster bootstrap tool)
  - `kubectl` (CLI tool)
- Configures containerd with `systemd` cgroup driver
- Loads required kernel modules
- Applies sysctl networking settings
- Enables and starts required services

---

## Kubernetes Version Management

The script uses a variable to control the Kubernetes version:

```bash
K8S_VERSION="v1.35"