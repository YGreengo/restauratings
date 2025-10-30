from flask import Blueprint, request, jsonify, current_app
from bson import ObjectId
from datetime import datetime
from models.restaurant import Restaurant, Review

restaurants_bp = Blueprint('restaurants', __name__)
allowed_cuisines = ['pizza', 'burger', 'israeli', 'cafe', 'pita', 'high_cuisine', 'italian', 'asian', 'vegetarian', 'bakery']

def get_mongo():
    """Get mongo instance from current app"""
    return current_app.mongo

def serialize_doc(doc):
    """Convert MongoDB document to JSON serializable format"""
    if doc is None:
        return None
    
    if isinstance(doc, list):
        return [serialize_doc(item) for item in doc]
    
    if isinstance(doc, dict):
        result = {}
        for key, value in doc.items():
            if isinstance(value, ObjectId):
                result[key] = str(value)
            elif isinstance(value, datetime):
                result[key] = value.isoformat()
            elif isinstance(value, dict):
                result[key] = serialize_doc(value)
            elif isinstance(value, list):
                result[key] = serialize_doc(value)
            else:
                result[key] = value
        return result
    
    return doc

@restaurants_bp.route('/api/restaurants', methods=['GET'])
def get_restaurants():
    try:
        mongo = get_mongo()
        
        # Get query parameters
        style = request.args.get('style')
        lat = request.args.get('lat', type=float)
        lng = request.args.get('lng', type=float)
        radius = request.args.get('radius', default=10, type=float)
        
        # Build query
        query = {}
        if style:
            query['style'] = {'$regex': style, '$options': 'i'}
        
        # If location provided, add geographic filtering
        if lat and lng:
            query['latitude'] = {
                '$gte': lat - radius/111,  # Rough km to degree conversion
                '$lte': lat + radius/111
            }
            query['longitude'] = {
                '$gte': lng - radius/111,
                '$lte': lng + radius/111
            }
        
        restaurants = list(mongo.db.restaurants.find(query))
        # Serialize the documents
        serialized_restaurants = serialize_doc(restaurants)
        
        # Log structured data for EFK
        current_app.logger.info(
            f'Retrieved {len(restaurants)} restaurants',
            extra={
                'event': 'database_query',
                'collection': 'restaurants',
                'operation': 'find',
                'result_count': len(restaurants),
                'query_params': {'style': style, 'lat': lat, 'lng': lng, 'radius': radius}
            }
        )
        
        return jsonify(serialized_restaurants), 200
    except Exception as e:
        current_app.logger.error(
            f'Error retrieving restaurants: {str(e)}',
            extra={'event': 'database_error', 'collection': 'restaurants', 'operation': 'find'}
        )
        return jsonify({'error': str(e)}), 500

@restaurants_bp.route('/api/restaurants', methods=['POST'])
def add_restaurant():
    try:
        mongo = get_mongo()
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['name', 'address', 'latitude', 'longitude', 'style']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        # Validate cuisine type (MOVED HERE - BEFORE creating the Restaurant object)
        if data['style'].lower() not in allowed_cuisines:
            return jsonify({
                'error': f'Invalid cuisine type. Must be one of: {", ".join(allowed_cuisines)}'
            }), 400
        
        # Create restaurant object (AFTER validation)
        restaurant = Restaurant(
            name=data['name'],
            address=data['address'],
            latitude=data['latitude'],
            longitude=data['longitude'],
            style=data['style'],
            description=data.get('description', ''),
            phone=data.get('phone', ''),
            website=data.get('website', '')
        )
        
        result = mongo.db.restaurants.insert_one(restaurant.to_dict())
        return jsonify({'id': str(result.inserted_id), 'message': 'Restaurant added successfully'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@restaurants_bp.route('/api/restaurants/<restaurant_id>', methods=['GET'])
def get_restaurant(restaurant_id):
    try:
        mongo = get_mongo()
        
        # Validate ObjectId format
        if not ObjectId.is_valid(restaurant_id):
            return jsonify({"error": "Invalid restaurant ID format"}), 400
        
        restaurant = mongo.db.restaurants.find_one({'_id': ObjectId(restaurant_id)})
        if not restaurant:
            return jsonify({'error': 'Restaurant not found'}), 404
        
        # Get reviews for this restaurant
        reviews = list(mongo.db.reviews.find({'restaurant_id': restaurant_id}))
        restaurant['reviews'] = reviews
        
        # Serialize the document
        serialized_restaurant = serialize_doc(restaurant)
        
        return jsonify(serialized_restaurant), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
@restaurants_bp.route('/api/restaurants/<restaurant_id>', methods=['DELETE'])
def delete_restaurant(restaurant_id):
    try:
        mongo = get_mongo()
        
        # Validate ObjectId format
        if not ObjectId.is_valid(restaurant_id):
            return jsonify({"error": "Invalid restaurant ID format"}), 400
        
        # Convert string to ObjectId
        object_id = ObjectId(restaurant_id)
        
        # Find and delete the restaurant
        result = mongo.db.restaurants.delete_one({"_id": object_id})
        
        if result.deleted_count == 0:
            return jsonify({"error": "Restaurant not found"}), 404
        
        # Optional: Also delete all reviews for this restaurant
        mongo.db.reviews.delete_many({"restaurant_id": restaurant_id})
        
        return jsonify({
            "message": "Restaurant deleted successfully",
            "deleted_id": restaurant_id
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@restaurants_bp.route('/api/restaurants/<restaurant_id>/reviews', methods=['POST'])
def add_review(restaurant_id):
    try:
        mongo = get_mongo()
        
        # Validate ObjectId format
        if not ObjectId.is_valid(restaurant_id):
            return jsonify({"error": "Invalid restaurant ID format"}), 400
        
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['user_name', 'rating']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        # Validate rating
        if not 1 <= data['rating'] <= 5:
            return jsonify({'error': 'Rating must be between 1 and 5'}), 400
        
        # Check if restaurant exists
        if not mongo.db.restaurants.find_one({'_id': ObjectId(restaurant_id)}):
            return jsonify({'error': 'Restaurant not found'}), 404
        
        review = Review(
            restaurant_id=restaurant_id,
            user_name=data['user_name'],
            rating=data['rating'],
            comment=data.get('comment', '')
        )
        
        # Insert review
        mongo.db.reviews.insert_one(review.to_dict())
        
        # Update restaurant average rating
        reviews = list(mongo.db.reviews.find({'restaurant_id': restaurant_id}))
        total_rating = sum(review['rating'] for review in reviews)
        average_rating = total_rating / len(reviews)
        
        mongo.db.restaurants.update_one(
            {'_id': ObjectId(restaurant_id)},
            {
                '$set': {
                    'average_rating': round(average_rating, 1),
                    'total_reviews': len(reviews)
                }
            }
        )
        
        return jsonify({'message': 'Review added successfully'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@restaurants_bp.route('/api/restaurants/<restaurant_id>/reviews', methods=['GET'])
def get_reviews(restaurant_id):
    try:
        mongo = get_mongo()
        
        # Validate ObjectId format
        if not ObjectId.is_valid(restaurant_id):
            return jsonify({"error": "Invalid restaurant ID format"}), 400
        
        reviews = list(mongo.db.reviews.find({'restaurant_id': restaurant_id}).sort('created_at', -1))
        
        # Serialize the documents
        serialized_reviews = serialize_doc(reviews)
        
        return jsonify(serialized_reviews), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500