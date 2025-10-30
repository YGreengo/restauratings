from datetime import datetime
from bson import ObjectId

class Restaurant:
    def __init__(self, name, address, latitude, longitude, style, description="", phone="", website=""):
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.style = style
        self.description = description
        self.phone = phone
        self.website = website
        self.created_at = datetime.utcnow()
        self.average_rating = 0.0
        self.total_reviews = 0

    def to_dict(self):
        return {
            'name': self.name,
            'address': self.address,
            'latitude': self.latitude,
            'longitude': self.longitude,
            'style': self.style,
            'description': self.description,
            'phone': self.phone,
            'website': self.website,
            'created_at': self.created_at,
            'average_rating': self.average_rating,
            'total_reviews': self.total_reviews
        }

class Review:
    def __init__(self, restaurant_id, user_name, rating, comment=""):
        self.restaurant_id = restaurant_id
        self.user_name = user_name
        self.rating = rating
        self.comment = comment
        self.created_at = datetime.utcnow()

    def to_dict(self):
        return {
            'restaurant_id': self.restaurant_id,
            'user_name': self.user_name,
            'rating': self.rating,
            'comment': self.comment,
            'created_at': self.created_at
        }