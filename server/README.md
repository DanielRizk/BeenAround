## FastAPI + Postgres (2 containers) — no Alembic, no migrations

### 1) Create .env
Copy `.env.example` to `.env` and edit values:
- JWT_SECRET should be long & random
- POSTGRES_PASSWORD should be strong

### 2) Build
docker compose build

### 3) Run
docker compose up -d

API:
http://localhost:8080

### 4) Health check
GET /health

### 5) Register/login flow
- POST /auth/register
- POST /auth/login
- GET /users/me with Authorization: Bearer <token>

### 6) Scaling
docker compose up -d --scale api=3

NOTE:
This project uses SQLAlchemy create_all() on startup (no migrations).
Good for learning/prototypes. For long-term production schema evolution,
use Alembic later.
