FROM ubuntu:24.04

# Install OpenSSH server
RUN apt-get update && apt-get install -y \
    openssh-server \
    sudo \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create demo user
RUN useradd -m -s /bin/bash admin && \
    echo "admin:cloudflare" | chpasswd && \
    usermod -aG sudo admin

# SSH directory setup
RUN mkdir -p /run/sshd /etc/ssh/auth_principals

# Trust the Cloudflare SSH CA — short-lived certs issued by Access
# This is the CA for TestEntAcc (account 531453e514d4dd7c94e710a1f5354bc6)
RUN echo "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFPZeNScFjTtlpdeqv7iaYudTdLlJJmQ9D9pOyEIUSdraOCTkWEqxHwidsNYsa9yhMbxXaIimt2LmSpIKCFMoWQ= open-ssh-ca@cloudflareaccess.org" \
    > /etc/ssh/cloudflare_ca.pub

# Configure sshd
RUN cat > /etc/ssh/sshd_config << 'EOF'
Port 22
ListenAddress 0.0.0.0

# Allow only Cloudflare CA-issued short-lived certs
TrustedUserCAKeys /etc/ssh/cloudflare_ca.pub

# No password auth, no static keys — Zero Trust only
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no

# Map certificate principal to local user
AuthorizedPrincipalsFile /etc/ssh/auth_principals/%u

# Misc hardening
PermitRootLogin no
X11Forwarding no
PrintMotd yes
AcceptEnv LANG LC_*

# Required for containers
UsePAM yes
EOF

# Map the 'admin' principal to the local 'admin' user
# Cloudflare Access issues certs with the user's email as principal
# We allow maksim@cloudflare.com to log in as admin
RUN echo "maksim@cloudflare.com" > /etc/ssh/auth_principals/admin

# MOTD — shows this is a Zero Trust protected server (good for demo)
RUN cat > /etc/motd << 'EOF'

  ██████╗██╗      ██████╗ ██╗   ██╗██████╗ ███████╗██╗      █████╗ ██████╗ ███████╗
 ██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗██╔════╝██║     ██╔══██╗██╔══██╗██╔════╝
 ██║     ██║     ██║   ██║██║   ██║██║  ██║█████╗  ██║     ███████║██████╔╝█████╗
 ██║     ██║     ██║   ██║██║   ██║██║  ██║██╔══╝  ██║     ██╔══██║██╔══██╗██╔══╝
 ╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝██║     ███████╗██║  ██║██║  ██║███████╗
  ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝

  Zero Trust SSH — Access for Infrastructure
  Authenticated via Cloudflare short-lived certificate
  No passwords. No static keys. Identity-based access only.

EOF

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D", "-e"]
