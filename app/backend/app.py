from flask import Flask, request, jsonify, send_from_directory, send_file
from flask_pymongo import PyMongo
from flask_cors import CORS
from bson import ObjectId
from datetime import datetime
import os
import json
import time
import logging
from logging.handlers import RotatingFileHandler
from dotenv import load_dotenv
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST

load_dotenv()

static_url_path = os.getenv('STATIC_URL_PATH', '')
app = Flask(__name__, static_folder='static', static_url_path=static_url_path)

# Prometheus metrics
REQUEST_COUNT = Counter('flask_requests_total', 'Total Flask requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('flask_request_duration_seconds', 'Flask request duration')
ACTIVE_CONNECTIONS = Gauge('flask_active_connections', 'Active Flask connections')
DB_CONNECTIONS = Gauge('mongodb_connections_active', 'Active MongoDB connections')

# MongoDB configuration
MONGODB_URI = os.getenv('MONGODB_URI', 'mongodb://db:27017/restaurant_db')
app.config['MONGO_URI'] = MONGODB_URI
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')

# Initialize MongoDB connection
mongo = PyMongo(app)
CORS(app)

# Make mongo available globally
app.mongo = mongo

# Configure structured logging for EFK stack
class JsonFormatter(logging.Formatter):
    def format(self, record):
        log_entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'module': record.module,
            'function': record.funcName,
            'line': record.lineno
        }
        
        # Add request context if available
        if hasattr(record, 'method'):
            log_entry['http_method'] = record.method
        if hasattr(record, 'url'):
            log_entry['url'] = record.url
        if hasattr(record, 'status_code'):
            log_entry['status_code'] = record.status_code
        if hasattr(record, 'duration'):
            log_entry['duration_ms'] = record.duration
            
        return json.dumps(log_entry)

# Setup JSON logging
if not app.debug:
    # Create logs directory if it doesn't exist
    os.makedirs('logs', exist_ok=True)
    
    formatter = JsonFormatter()
    handler = RotatingFileHandler('logs/app.log', maxBytes=10000000, backupCount=3)
    handler.setFormatter(formatter)
    handler.setLevel(logging.INFO)
    app.logger.addHandler(handler)
    app.logger.setLevel(logging.INFO)
    app.logger.info('Application startup', extra={'event': 'startup'})

# Monitoring middleware
@app.before_request
def before_request():
    request.start_time = time.time()
    ACTIVE_CONNECTIONS.inc()

@app.after_request
def after_request(response):
    request_duration = time.time() - request.start_time
    
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.endpoint or 'unknown',
        status=response.status_code
    ).inc()
    
    REQUEST_DURATION.observe(request_duration)
    ACTIVE_CONNECTIONS.dec()
    
    # Log request in JSON format
    app.logger.info(
        f'{request.method} {request.url} - {response.status_code}',
        extra={
            'method': request.method,
            'url': request.url,
            'status_code': response.status_code,
            'duration': round(request_duration * 1000, 2),
            'event': 'http_request'
        }
    )
    
    return response

# JSON encoder for ObjectId
class JSONEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, ObjectId):
            return str(obj)
        if isinstance(obj, datetime):
            return obj.isoformat()
        return super().default(obj)

app.json_encoder = JSONEncoder

# Import and register API blueprints
from routes.restaurants import restaurants_bp
app.register_blueprint(restaurants_bp)

# Serve React App
@app.route('/')
def serve_react_app():
    # Check if React build exists in the build directory
    build_path = os.path.join(app.root_path, 'build', 'index.html')
    if os.path.exists(build_path):
        return send_file(build_path)
    else:
        # Fallback to API info if no React build
        return jsonify({
            'message': 'Restaurant SaaS API',
            'version': '1.0',
            'architecture': '3-tier: nginx -> flask -> mongodb',
            'endpoints': {
                'restaurants': '/api/restaurants',
                'health': '/health'
            },
            'note': f'React frontend not found at {build_path}'
        })

@app.route('/<path:path>')
def serve_react_static(path):
    # If it's an API route, let it pass through to blueprints
    if path.startswith('api/'):
        return jsonify({"error": "API endpoint not found"}), 404
    
    
    # For all other paths, serve React app (SPA routing)
    build_path = os.path.join(app.root_path, 'build', 'index.html')
    if os.path.exists(build_path):
        return send_file(build_path)
    else:
        return serve_react_app()  # Fallback to root handler

# Prometheus metrics endpoint
@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

# Health check
@app.route('/health')
def health_check():
    return jsonify({'status': 'healthy', 'service': 'app'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=os.getenv('FLASK_ENV') == 'development')