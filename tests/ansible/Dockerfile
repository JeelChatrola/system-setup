ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

# Only test-harness prerequisites; all managed packages are installed by Ansible.
RUN if command -v apt-get >/dev/null; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y python3 sudo ca-certificates && \
      printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d && \
      chmod +x /usr/sbin/policy-rc.d; \
    else \
      pacman -Syu --noconfirm python sudo ca-certificates; \
    fi && \
    useradd --create-home --shell /bin/bash tester

CMD ["sleep", "infinity"]
