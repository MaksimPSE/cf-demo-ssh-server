FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    openssh-server \
    sudo \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create demo user
RUN useradd -m -s /bin/bash admin && \
    echo "admin:cloudflare" | chpasswd && \
    usermod -aG sudo admin

# Generate host keys
RUN ssh-keygen -A

# Runtime directories sshd needs
RUN mkdir -p /run/sshd /var/run/sshd /etc/ssh/auth_principals

# Trust the Cloudflare SSH CA
RUN echo "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFPZeNScFjTtlpdeqv7iaYudTdLlJJmQ9D9pOyEIUSdraOCTkWEqxHwidsNYsa9yhMbxXaIimt2LmSpIKCFMoWQ= open-ssh-ca@cloudflareaccess.org" \
    > /etc/ssh/cloudflare_ca.pub

# Copy sshd config
COPY sshd_config /etc/ssh/sshd_config

# Map principal to local user
RUN echo "maksim@cloudflare.com" > /etc/ssh/auth_principals/admin

# MOTD
RUN printf '\n  Cloudflare Zero Trust SSH\n  No passwords. No static keys.\n\n' > /etc/motd

# Validate config at build time
RUN sshd -t && echo "sshd config OK"

EXPOSE 22

# Run sshd with debug output so errors are visible in container logs
CMD ["/usr/sbin/sshd", "-D", "-e", "-f", "/etc/ssh/sshd_config"]
