\# HNG Stage 2 - Blue/Green Deployment with Nginx



\## Overview

This project implements a Blue/Green deployment strategy with automatic failover using Nginx upstreams.



\## Architecture

\- \*\*Nginx\*\* (Port 8080): Reverse proxy with failover logic

\- \*\*Blue App\*\* (Port 8081): Primary application instance

\- \*\*Green App\*\* (Port 8082): Backup application instance



\## Quick Start



1\. \*\*Copy environment file:\*\*

&nbsp;  ```bash

&nbsp;  cp .env.example .env

