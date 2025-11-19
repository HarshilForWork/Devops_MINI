# MySQL Database Configuration

This folder contains database initialization and schema files.

## Files

- **init.sql** - Auto-runs when Docker container starts (for local development)
- **schema.sql** - Manual schema for production GCP database setup

## Local Development (Docker)

The `init.sql` file will automatically:
- Create `users` and `books` tables
- Add indexes
- Insert sample test data

## Production Setup (GCP)

Run `schema.sql` manually on your GCP MySQL instance:

```bash
mysql -h <GCP_DB_IP> -u root -p < database/schema.sql
```

## Database Schema

### users
- id (INT, PRIMARY KEY)
- name (VARCHAR)
- email (VARCHAR, UNIQUE)
- password (VARCHAR, hashed)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)

### books
- id (INT, PRIMARY KEY)
- title (VARCHAR)
- author (VARCHAR)
- user_id (INT, FOREIGN KEY)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
