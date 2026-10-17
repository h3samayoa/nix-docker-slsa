FROM nixos/nix:2.35.3-amd64

RUN set -eux; \
    { \
        echo "filter-syscalls = false"; \
        echo "max-jobs = auto"; \
    } >> /etc/nix/nix.conf

RUN nix-env -f '<nixpkgs>' -iA gnused && nix-store --gc

RUN set -eux; \
    mkdir -p /etc/ssh /var/empty /run /var/log /root/.ssh; \
    chmod 700 /root/.ssh; \
    touch /var/log/lastlog; \
    echo "sshd:x:498:65534::/var/empty:/run/current-system/sw/bin/nologin" >> /etc/passwd; \
    sed -i 's/^root:!:/root:*:/' /etc/shadow; \
    { \
        echo "HostKey /etc/ssh/ssh_host_ed25519_key"; \
        echo "PermitRootLogin prohibit-password"; \
        echo "PasswordAuthentication no"; \
        echo "KbdInteractiveAuthentication no"; \
        echo "UsePAM no"; \
        echo "AllowTcpForwarding no"; \
        echo "AllowAgentForwarding no"; \
        echo "X11Forwarding no"; \
    } > /etc/ssh/sshd_config; \
    echo "source /root/.nix-profile/etc/profile.d/nix.sh" >> /etc/bashrc; \
    echo "source /etc/bashrc" >> /etc/profile

COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
