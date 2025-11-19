# How Containers Communicate: Local vs GCP

## The Simple Answer

### Local Development (What You Just Ran)
```
Your Computer
    ↓
Docker Compose creates a virtual network
    ↓
book_app connects to "db" (Docker gives it the IP automatically)
    ↓
MySQL responds
```

### GCP Production (What We'll Deploy)
```
Internet
    ↓
App VM (10.128.0.3) - Flask app running in Docker
    ↓
GCP's internal network
    ↓
Database VM (10.128.0.4) - MySQL running in Docker
    ↓
MySQL responds
```

---

## The Key Difference in One Picture

```
┌─────────────────────────────────────────────────────┐
│         LOCAL: Single Computer                      │
├─────────────────────────────────────────────────────┤
│                                                     │
│    Docker Network (like a mini internet)           │
│    ┌──────────┐           ┌──────────┐            │
│    │ book_app │─── db ───▶│ book_db  │            │
│    └──────────┘           └──────────┘            │
│                                                     │
│    "db" = Docker translates to container IP        │
└─────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────┐
│         GCP: Three Separate Computers               │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Google's Internet (VPC)                           │
│                                                     │
│  ┌─────────────┐        ┌─────────────┐           │
│  │   App VM    │        │ Database VM │           │
│  │ 10.128.0.3  │        │ 10.128.0.4  │           │
│  │             │        │             │           │
│  │ ┌─────────┐ │        │ ┌─────────┐ │           │
│  │ │book_app │─┼────────┼▶│book_db  │ │           │
│  │ └─────────┘ │        │ └─────────┘ │           │
│  └─────────────┘        └─────────────┘           │
│                                                     │
│  MYSQL_HOST=10.128.0.4 (must be exact IP)         │
└─────────────────────────────────────────────────────┘
```

---

## What Changes in Your Code?

### Nothing! Your Python code stays the same:

```python
# frontend/config.py (SAME CODE in both environments)
MYSQL_HOST = os.getenv('MYSQL_HOST', 'localhost')
```

### Only the environment variable changes:

**Local:**
```bash
MYSQL_HOST=db  # Docker DNS resolves "db" to book_db container
```

**GCP:**
```bash
MYSQL_HOST=10.128.0.4  # Must use actual VM's internal IP address
```

---

## Why Can't We Use "db" in GCP?

**Docker DNS only works on the same machine:**
- Local: Both containers are on your computer → Docker connects them
- GCP: Containers are on different computers → Docker can't connect them

**In GCP, you need the actual IP address:**
- Database VM has IP: 10.128.0.4
- App VM needs to know: "Connect to 10.128.0.4:3306"
- Google's network routes the traffic between VMs

---

## Step-by-Step: What Happens When App Connects to Database

### Local (docker-compose up)

1. **You run:** `docker-compose up`
2. **Docker creates:** A virtual network named "book_network"
3. **Docker starts:** book_db container (joins book_network)
4. **Docker starts:** book_app container (joins book_network)
5. **Docker DNS:** Registers "db" → points to book_db's IP (e.g., 172.18.0.2)
6. **Your app:** Connects to "db:3306"
7. **Docker DNS:** Translates "db" → 172.18.0.2
8. **Connection:** Successful! ✓

### GCP (3 separate VMs)

1. **You run:** `gcloud compute instances create database-vm`
2. **GCP assigns:** Internal IP 10.128.0.4 to database-vm
3. **You run:** Docker on database-vm with `-p 3306:3306` (exposes port)
4. **You run:** `gcloud compute instances create app-vm`
5. **GCP assigns:** Internal IP 10.128.0.3 to app-vm
6. **You run:** Docker on app-vm with `-e MYSQL_HOST=10.128.0.4`
7. **Your app:** Connects to "10.128.0.4:3306"
8. **GCP network:** Routes traffic from 10.128.0.3 → 10.128.0.4
9. **Connection:** Successful! ✓

---

## Common Questions

### Q: Why not just use "db" in GCP too?
**A:** Docker DNS only works within a single Docker network on one machine. In GCP, each VM has its own Docker installation that doesn't know about other VMs.

### Q: Can we make the VMs share a Docker network?
**A:** No, Docker networks are local to one machine. But you can use:
- **Docker Swarm**: Multi-host Docker orchestration
- **Kubernetes**: Advanced container orchestration (what GKE uses)
- **Manual networking**: What we're doing (simplest for learning)

### Q: What if the IP changes?
**A:** GCP internal IPs are stable, but best practices:
- Use environment variables (already doing this! ✓)
- Use Cloud DNS for internal hostnames
- Use managed databases (Cloud SQL) with connection names

### Q: Is this secure?
**A:** In GCP:
- Internal IPs only work inside your VPC (not from internet)
- Still need firewall rules to allow port 3306
- Best practice: Use Cloud SQL (managed database) instead of self-hosted MySQL

---

## Quick Reference

| What | Local Value | GCP Value |
|------|-------------|-----------|
| **MYSQL_HOST** | `db` | `10.128.0.4` |
| **Network Type** | Docker bridge | GCP VPC |
| **DNS** | Docker DNS | No DNS (use IPs) |
| **Port Exposure** | Optional | Required (`-p 3306:3306`) |
| **Firewall** | Not needed | Required (allow port 3306) |

---

## Testing Your Understanding

Try to answer these without looking:

1. **Why does `MYSQL_HOST=db` work locally?**
   <details>
   <summary>Answer</summary>
   Docker Compose creates a network and DNS that translates "db" to the container's IP.
   </details>

2. **Why won't `MYSQL_HOST=db` work in GCP?**
   <details>
   <summary>Answer</summary>
   Containers are on different VMs, each with separate Docker installations. Docker DNS doesn't work across VMs.
   </details>

3. **How do we fix it in GCP?**
   <details>
   <summary>Answer</summary>
   Use the Database VM's internal IP address (e.g., MYSQL_HOST=10.128.0.4).
   </details>

4. **Does our Python code need to change?**
   <details>
   <summary>Answer</summary>
   No! The code uses os.getenv('MYSQL_HOST'), so we just change the environment variable.
   </details>

---

## Ready to Deploy?

1. **Test locally first** (you already did this! ✓)
   ```bash
   docker-compose up -d
   curl http://localhost:5000
   ```

2. **When ready for GCP**, follow: `GCP_DEPLOYMENT_GUIDE.md`
   - Create 3 VMs
   - Get Database VM's internal IP
   - Update MYSQL_HOST to that IP
   - Deploy!

**Pro tip:** Keep your local environment running so you can test changes before deploying to GCP!
