# Restauratings Application

This is the core repository for the **Restauratings** app, a full-stack web application for browsing, reviewing, and locating restaurants on a map.

---

## 🌐 Overview

- **Three-tier architecture**: Frontend, backend, and database layers deployed with **network separation**
- **Frontend**: React.js SPA, proxied through NGINX
- **Backend**: Flask API with Prometheus metrics, MongoDB integration, and structured logging (JSON for EFK)
- **Database**: MongoDB with initial data + indexes
- **Infrastructure**: Docker Compose for local dev; integrates into a GitOps EKS environment in production

---

## ♻️ Repository Structure

```
.
├── backend/              # Flask app with API and metrics
├── frontend/             # React app (map + reviews UI)
├── nginx/                # Reverse proxy for frontend/backend/static
├── tests/                # Unit and E2E test scripts
├── init-mongo.js         # MongoDB init script (collections, indexes)
├── seed_data.py          # Optional data seeding script
├── docker-compose.yaml   # Local dev stack
├── Jenkinsfile           # CI pipeline
├── run-unit-tests.sh     # Local unit tests
├── run-e2e-tests.sh      # Local Cypress tests (or browser-based)
```

---

## 🌟 Features

- View restaurants on an interactive map by category (pizza, burger, vegetarian, etc.)
- Submit and browse reviews for each restaurant
- Built-in Prometheus `/metrics` and `/health` endpoints
- Logs in JSON for easy ingestion by EFK stack
- React frontend built and served via Flask
- **Static assets** served directly by **NGINX** with long-term caching

---

## 🌭 Tech Stack

| Layer         | Tech                              |
| ------------- | --------------------------------- |
| Frontend      | React, Axios, Leaflet             |
| Backend       | Flask, PyMongo, Prometheus        |
| Database      | MongoDB                           |
| Logging       | JSON + Rotating FileHandler       |
| Dev Tools     | Docker Compose, Jenkins           |
| Reverse Proxy | NGINX (serves static + API proxy) |

---

## 🚀 Quick Start (Local)

```bash
# Copy .env.example to .env and fill in required values
cp .env.example .env

# Start app
docker compose up --build

# App available at http://localhost
```

---

## ⚙️ API Endpoints

```
GET    /api/restaurants
GET    /api/restaurants/:id
POST   /api/restaurants
POST   /api/restaurants/:id/reviews
GET    /api/restaurants/:id/reviews
```

- **Health**: `/health`
- **Metrics**: `/metrics`

---

## 🌐 Environment Variables

Required via `.env`:

```env
MONGODB_URI=mongodb://...
SECRET_KEY=...
FLASK_ENV=production
GOOGLE_MAPS_API_KEY=...
```

---

## 📖 NGINX Behavior

The `nginx` container:

- Serves static files (e.g., `/static`) with long-term caching and security headers
- Proxies all `/api` calls to the Flask backend
- Routes all other requests (React routes) to the Flask server

---

## 📚 Sample Seed Data

Run this to populate the DB with Israeli restaurants and reviews:

```bash
python backend/seed_data.py
```

Or initialize via container:

```bash
docker compose up --build
```

`init-mongo.js` runs automatically via MongoDB's init script.

---

## 🛠️ CI Pipeline

- CI defined via `Jenkinsfile`
- Includes unit and E2E test stages
- `run-unit-tests.sh` and `run-e2e-tests.sh` can also be run locally

---

## ⚠️ Notes

- The backend serves both API and frontend static files
- API calls from the React app are proxied via NGINX and relative paths
- JSON logging is production-ready for ingestion by EFK stack

---

## 📅 Credits

Created by **Yarden Green** as part of a full-stack DevOps/GitOps portfolio project.

