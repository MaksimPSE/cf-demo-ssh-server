import { Container, getContainer } from "@cloudflare/containers";

// ─── SSH Server Container ─────────────────────────────────────────────────
// Runs OpenSSH configured to trust Cloudflare's SSH CA only.
// No passwords, no static keys — access exclusively via Access for Infrastructure
// short-lived certificates.
//
// Users connect via:
//   ssh -o ProxyCommand="cloudflared access ssh --hostname ssh.maksimplatform.ovh" admin@ssh.maksimplatform.ovh
// Or via WARP + Access for Infrastructure targets.

export class SSHContainer extends Container {
  defaultPort = 22;

  // Keep SSH server alive indefinitely — it's an always-on service
  sleepAfter = "24h";

  onStart() {
    console.log("[ssh-server] container started — Zero Trust SSH ready");
  }

  onStop() {
    console.log("[ssh-server] container stopped");
  }

  onError(error) {
    console.error("[ssh-server] container error:", error);
  }
}

// ─── Worker fetch handler ─────────────────────────────────────────────────
// HTTP handler is used only for health checks and the cloudflared tunnel
// to route SSH traffic into the container.
// The actual SSH connection goes TCP → cloudflared → Worker → Container port 22.

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // Health check
    if (url.pathname === "/health") {
      return new Response("ssh-server ok", { status: 200 });
    }

    // All other HTTP traffic → route to container
    // (cloudflared sends SSH as HTTP/2 streams via the tunnel)
    return getContainer(env.SSH_SERVER, "ssh-singleton").fetch(request);
  },
};
