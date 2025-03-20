# Docker image for Certbot with Clouflare DNS challenge

- Compatible with Cloudflare via API Token as of June 30 2024.
- Attempts to renew certificates every 12 hours.
- Supports multiple domains.
- Certificates are placed in /certs, in format [domain].crt (full certificate chain) and [domain].key (private key).
  - Compatible with the [nginx-proxy image](https://github.com/nginx-proxy/nginx-proxy). Refer to [nginx-proxy's SSL Support documentation](https://github.com/nginx-proxy/nginx-proxy/tree/main/docs#ssl-support) for details on how to do this.

## Docker Compose

```yaml
services:
  certbot:
    container_name: certbot
    image: ghcr.io/mbogochow/docker-certbot-dns-cloudflare:latest
    environment:
      - CLOUDFLARE_API_TOKEN=your_cloudflare_api_token_here # your Cloudflare API token
      - EMAIL=your_email@example.com                        # your Cloudflare email
      - DOMAIN=example.com,*.example.com                    # domains to create certificate for separate by commas
      - DRY_RUN=0                                           # set to 1 to perform a dry run without saving certificates
      - PROPAGATION=60                                      # optional: seconds to wait for DNS propagation (default: not set)
    volumes:
      - ./certs:/certs                          # where the certs will be stored
      - ./letsencrypt:/etc/letsencrypt          # required by certbot
      - ./letsencrypt-lib:/var/lib/letsencrypt  # optional
      - ./letsencrypt-log:/var/log/letsencrypt  # optional for persistent logging
    restart: unless-stopped # Set to no for debugging
```
