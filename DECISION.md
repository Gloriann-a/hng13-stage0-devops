\# Architecture Decisions - HNG Stage 2



\## Design Choices



\### 1. Nginx Upstream Configuration

\- Used `max\_fails=2` and `fail\_timeout=10s` for quick failure detection

\- Designated Green as `backup` to only activate when Blue fails

\- This ensures zero failed client requests during failover



\### 2. Failover Strategy

\- `proxy\_next\_upstream` configured to retry on errors, timeouts, and 5xx status codes

\- Fast timeouts (2s connect, 5s read) for rapid failure detection

\- `proxy\_buffering off` ensures real-time response during failover



\### 3. Health Checking

\- Docker healthchecks monitor `/healthz` endpoint

\- 5-second intervals with 3-second timeouts for responsive monitoring

\- 2 retries before marking container as unhealthy



\### 4. Header Preservation

\- Configured to forward all application headers unchanged

\- This preserves `X-App-Pool` and `X-Release-Id` headers as required



\## Trade-offs

\- Faster failover means potentially more false positives

\- Simple backup strategy vs more complex load balancing

\- Focused on reliability over advanced features

