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

# Generate host keys explicitly (needed for sshd to start)
RUN ssh-keygen -A

# Required runtime directory for sshd privilege separation
RUN mkdir -p /run/sshd /etc/ssh/auth_principals /var/run/sshd

# Trust the Cloudflare SSH CA
RUN echo "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFPZeNScFjTtlpdeqv7iaYudTdLlJJmQ9D9pOyEIUSdraOCTkWEqxHwidsNYsa9yhMbxXaIimt2LmSpIKCFMoWQ= open-ssh-ca@cloudflareaccess.org" \
    > /etc/ssh/cloudflare_ca.pub

# Copy sshd config
COPY sshd_config /etc/ssh/sshd_config

# Map maksim@cloudflare.com certificate principal to local admin user
RUN echo "maksim@cloudflare.com" > /etc/ssh/auth_principals/admin

# MOTD
RUN printf '\n  Cloudflare Zero Trust SSH\n  Authenticated via short-lived certificate\n  No passwords. No static keys.\n\n' > /etc/motd

EXPOSE 22

# Test config is valid before finalising image
RUN sshd -t && echo "sshd config OK"

CMD ["/usr/sbin/sshd", "-D", "-e"]
