// MongoDB initialization script
db = db.getSiblingDB('restaurant_db');

// Create collections
db.createCollection('restaurants');
db.createCollection('reviews');

// Create indexes for better performance
db.restaurants.createIndex({ "latitude": 1, "longitude": 1 });
db.restaurants.createIndex({ "style": 1 });
db.restaurants.createIndex({ "name": "text", "description": "text" });
db.reviews.createIndex({ "restaurant_id": 1 });

print('Database initialized successfully');