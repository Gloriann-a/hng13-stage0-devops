
---

## **DECISION.md**

```markdown
# Design Decisions

## 1. Blue/Green Deployment
- Two separate app containers (`app_blue` and `app_green`) running on ports 8081 and 8082.
- Nginx routes traffic based on the `ACTIVE_POOL` environment variable.

## 2. Nginx Configuration
- Upstreams defined for `blue_backend` and `green_backend`.
- Uses a `map` block to select active backend dynamically.
- Proxy settings include timeouts, error handling, and retries:
  - `proxy_next_upstream` ensures auto-failover if an upstream fails.
  - Timeouts are set for connecting, sending, and receiving.

## 3. Docker Compose
- Defines services for `nginx`, `app_blue`, and `app_green`.
- Uses `.env` variables for image names and release IDs.

## 4. Environment Management
- `.env` defines images and release IDs.
- `.env.example` provided for submission without secrets.

## 5. Challenges
- Initial Nginx 404 issues due to default `index` file.
- Resolved by correctly proxying `/version` and `/healthz` endpoints.
- Ensured Nginx template (`nginx.conf.template`) works with envsubst.

## 6. Notes
- Optional chaos testing endpoints exist in each app container.
- Nginx logs and `curl` commands can be used to verify traffic routing.



