# Stage 1: Build React frontend
FROM node:20-alpine as react-builder

WORKDIR /frontend

# Accept build argument for API key
ARG REACT_APP_GOOGLE_MAPS_API_KEY
ENV REACT_APP_GOOGLE_MAPS_API_KEY=$REACT_APP_GOOGLE_MAPS_API_KEY

# Copy package files
COPY frontend/package*.json ./
RUN npm ci

# Copy frontend source code
COPY frontend/ ./

# Build React app (API key gets baked in)
RUN npm run build

# Stage 2: Flask application
FROM python:3.9-alpine

WORKDIR /app

# Install system dependencies
RUN apk add --no-cache \
    gcc \
    musl-dev \
    linux-headers \
    && rm -rf /var/cache/apk/*

# Copy Python requirements and install dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy Flask application code
COPY backend/ .

# Copy React build from stage 1 (entire build directory)
COPY --from=react-builder /frontend/build ./build

# Copy just the static files to the shared volume location
COPY --from=react-builder /frontend/build/static ./static

# Expose port
EXPOSE 5000

ENV FLASK_ENV=production

CMD ["python", "app.py"]