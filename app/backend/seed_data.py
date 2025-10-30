import time
from pymongo import MongoClient
from datetime import datetime
import os

MONGO_URI = os.getenv("MONGODB_URI") 
client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)

# Wait for MongoDB to be ready
def wait_for_mongo():
    max_retries = 30
    for i in range(max_retries):
        try:
            client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
            client.admin.command('ping')
            print("MongoDB is ready!")
            return client
        except Exception:
            print(f"Waiting for MongoDB... ({i+1}/{max_retries})")
            time.sleep(2)
    raise RuntimeError("MongoDB is not ready after 30 retries")


# Connect to MongoDB
client = wait_for_mongo()
db = client.get_default_database()  

# Israeli restaurants with expanded cuisine types
israeli_restaurants = [
    # Pizza restaurants
    {
        "name": "Tony's Pizza",
        "address": "12 Dizengoff St, Tel Aviv, Israel",
        "latitude": 32.0739,
        "longitude": 34.7718,
        "style": "pizza",
        "description": "Authentic Italian pizza with Israeli twist",
        "phone": "+972-3-525-1234",
        "website": "https://www.tonyspizza.co.il",
        "created_at": datetime.utcnow(),
        "average_rating": 4.5,
        "total_reviews": 28
    },
    {
        "name": "Pizza Sababa",
        "address": "45 Ben Yehuda St, Jerusalem, Israel",
        "latitude": 31.7857,
        "longitude": 35.2007,
        "style": "pizza",
        "description": "Best pizza in Jerusalem with fresh ingredients",
        "phone": "+972-2-625-7890",
        "website": "",
        "created_at": datetime.utcnow(),
        "average_rating": 4.3,
        "total_reviews": 22
    },
    
    # Burger restaurants
    {
        "name": "Moses Burger",
        "address": "88 Rothschild Blvd, Tel Aviv, Israel",
        "latitude": 32.0668,
        "longitude": 34.7692,
        "style": "burger",
        "description": "Gourmet burgers with Israeli flavors",
        "phone": "+972-3-566-1122",
        "website": "https://www.mosesburger.com",
        "created_at": datetime.utcnow(),
        "average_rating": 4.6,
        "total_reviews": 35
    },
    {
        "name": "HaBurger",
        "address": "23 Allenby St, Tel Aviv, Israel",
        "latitude": 32.0713,
        "longitude": 34.7692,
        "style": "burger",
        "description": "Classic American-style burgers in the heart of Tel Aviv",
        "phone": "+972-3-510-3344",
        "website": "",
        "created_at": datetime.utcnow(),
        "average_rating": 4.4,
        "total_reviews": 31
    },
    
    # Israeli cuisine
    {
        "name": "Machneyuda",
        "address": "10 Beit Yaakov St, Jerusalem, Israel",
        "latitude": 31.7683,
        "longitude": 35.2137,
        "style": "israeli",
        "description": "Modern Israeli cuisine in vibrant atmosphere",
        "phone": "+972-2-533-3442",
        "website": "https://www.machneyuda.co.il",
        "created_at": datetime.utcnow(),
        "average_rating": 4.8,
        "total_reviews": 42
    },
    {
        "name": "Shakshukia",
        "address": "3 Beit Eshel St, Jaffa, Tel Aviv, Israel",
        "latitude": 32.0546,
        "longitude": 34.7521,
        "style": "israeli",
        "description": "Famous for authentic shakshuka and Israeli breakfast",
        "phone": "+972-3-681-8842",
        "website": "",
        "created_at": datetime.utcnow(),
        "average_rating": 4.5,
        "total_reviews": 29
    },
    
    # Cafes
    {
        "name": "Cafe Xoho",
        "address": "23 Yoel Moshe Salomon St, Jerusalem, Israel",
        "latitude": 31.7857,
        "longitude": 35.2007,
        "style": "cafe",
        "description": "Cozy Jerusalem cafe with excellent coffee and pastries",
        "phone": "+972-2-625-2114",
        "website": "",
        "created_at": datetime.utcnow(),
        "average_rating": 4.2,
        "total_reviews": 25
    },
    {
        "name": "Aroma Espresso Bar",
        "address": "174 Ben Yehuda St, Tel Aviv, Israel",
        "latitude": 32.0804,
        "longitude": 34.7739,
        "style": "cafe",
        "description": "Israeli coffee chain with excellent espresso and sandwiches",
        "phone": "+972-3-522-7788",
        "website": "https://www.aroma.co.il",
        "created_at": datetime.utcnow(),
        "average_rating": 4.0,
        "total_reviews": 40
    },
    
    # Pita restaurants
    {
        "name": "Miznon",
        "address": "23 Ibn Gabirol St, Tel Aviv, Israel",
        "latitude": 32.0739,
        "longitude": 34.7718,
        "style": "pita",
        "description": "Famous pita bar with creative Mediterranean dishes",
        "phone": "+972-3-611-1196",
        "website": "https://www.miznon.com",
        "created_at": datetime.utcnow(),
        "average_rating": 4.7,
        "total_reviews": 45
    },
    {
        "name": "Falafel Hakosem",
        "address": "1 Shlomo HaMelech St, Tel Aviv, Israel",
        "latitude": 32.0713,
        "longitude": 34.7692,
        "style": "pita",
        "description": "Best falafel in pita in Tel Aviv",
        "phone": "+972-3-525-2033",
        "website": "",
        "created_at": datetime.utcnow(),
        "average_rating": 4.6,
        "total_reviews": 52
    },
    
    # High Cuisine
    {
        "name": "HaSalon",
        "address": "90 Ibn Gabirol St, Tel Aviv, Israel",
        "latitude": 32.0804,
        "longitude": 34.7806,
        "style": "high_cuisine",
        "description": "Chef Eyal Shani's innovative fine dining experience",
        "phone": "+972-3-691-4251",
        "website": "https://www.hasalon.co.il",
        "created_at": datetime.utcnow(),
        "average_rating": 4.9,
        "total_reviews": 38
    },
    {
        "name": "Eucalyptus",
        "address": "14 Hativat Yerushalayim St, Jerusalem, Israel",
        "latitude": 31.7683,
        "longitude": 35.2137,
        "style": "high_cuisine",
        "description": "Biblical cuisine with modern twist, kosher fine dining",
        "phone": "+972-2-624-4331",
        "website": "https://www.eucalyptus-rest.com",
        "created_at": datetime.utcnow(),
        "average_rating": 4.8,
        "total_reviews": 25
    },
    
    # Italian
    {
        "name": "Pasta Basta",
        "address": "48 Rothschild Blvd, Tel Aviv, Israel",
        "latitude": 32.0668,
        "longitude": 34.7718,
        "style": "italian",
        "description": "Authentic Italian pasta and risotto restaurant",
        "phone": "+972-3-566-7788",
        "website": "https://www.pastabasta.co.il",
        "created_at": datetime.utcnow(),
        "average_rating": 4.4,
        "total_reviews": 33
    },
    {
        "name": "Pronto",
        "address": "4 Mendele St, Tel Aviv, Israel",
        "latitude": 32.0739,
        "longitude": 34.7692,
        "style": "italian",
        "description": "Classic Italian trattoria with homemade pasta",
        "phone": "+972-3-566-9911",
        "website": "",
        "created_at": datetime.utcnow(),
        "average_rating": 4.3,
        "total_reviews": 28
    },
    
    # Asian
    {
        "name": "Taizu",
        "address": "23 Menachem Begin Rd, Tel Aviv, Israel",
        "latitude": 32.0668,
        "longitude": 34.7806,
        "style": "asian",
        "description": "Modern Asian fusion with Israeli influences",
        "phone": "+972-3-522-5005",
        "website": "https://www.taizu.co.il",
        "created_at": datetime.utcnow(),
        "average_rating": 4.6,
        "total_reviews": 41
    },
    {
        "name": "Yakimono",
        "address": "7 Koifman St, Tel Aviv, Israel",
        "latitude": 32.0713,
        "longitude": 34.7739,
        "style": "asian",
        "description": "Japanese sushi and Asian street food",
        "phone": "+972-3-544-9988",
        "website": "",
        "created_at": datetime.utcnow(),
        "average_rating": 4.5,
        "total_reviews": 37
    },
    
    # Vegetarian
    {
        "name": "Meshek Barzilay",
        "address": "6 Ahad Ha'Am St, Tel Aviv, Israel",
        "latitude": 32.0668,
        "longitude": 34.7692,
        "style": "vegetarian",
        "description": "Farm-to-table vegetarian restaurant with organic ingredients",
        "phone": "+972-3-516-6329",
        "website": "https://www.meshekbarzilay.co.il",
        "created_at": datetime.utcnow(),
        "average_rating": 4.5,
        "total_reviews": 31
    },
    {
        "name": "Zakaim",
        "address": "35 King George St, Tel Aviv, Israel",
        "latitude": 32.0713,
        "longitude": 34.7718,
        "style": "vegetarian",
        "description": "Innovative vegetarian cuisine with global influences",
        "phone": "+972-3-525-7766",
        "website": "",
        "created_at": datetime.utcnow(),
        "average_rating": 4.4,
        "total_reviews": 26
    },
    
    # Bakery
    {
        "name": "Lehamim Bakery",
        "address": "45 Dizengoff St, Tel Aviv, Israel",
        "latitude": 32.0739,
        "longitude": 34.7739,
        "style": "bakery",
        "description": "Artisan bakery with fresh breads and pastries",
        "phone": "+972-3-522-3344",
        "website": "https://www.lehamim.co.il",
        "created_at": datetime.utcnow(),
        "average_rating": 4.3,
        "total_reviews": 29
    },
    {
        "name": "Roladin",
        "address": "123 Ben Yehuda St, Tel Aviv, Israel",
        "latitude": 32.0804,
        "longitude": 34.7718,
        "style": "bakery",
        "description": "Popular bakery chain with cakes, pastries and coffee",
        "phone": "+972-3-544-5577",
        "website": "https://www.roladin.co.il",
        "created_at": datetime.utcnow(),
        "average_rating": 4.1,
        "total_reviews": 35
    }
]

try:
    # Clear existing data first
    db.restaurants.delete_many({})
    db.reviews.delete_many({})
    print("Cleared existing restaurant and review data")
    
    # Insert Israeli restaurants
    result = db.restaurants.insert_many(israeli_restaurants)
    print(f"Inserted {len(result.inserted_ids)} Israeli restaurants")
    
    # Add some sample reviews
    restaurant_ids = result.inserted_ids
    israeli_reviews = [
        {
            "restaurant_id": str(restaurant_ids[0]),
            "user_name": "Sarah Cohen",
            "rating": 5,
            "comment": "הפיצה הכי טובה בתל אביב! חובה לטעום",
            "created_at": datetime.utcnow()
        },
        {
            "restaurant_id": str(restaurant_ids[10]),
            "user_name": "David Levi",
            "rating": 5,
            "comment": "Fine dining at its best! Incredible experience",
            "created_at": datetime.utcnow()
        },
        {
            "restaurant_id": str(restaurant_ids[14]),
            "user_name": "Rachel Green",
            "rating": 5,
            "comment": "Amazing Asian fusion! Creative and delicious",
            "created_at": datetime.utcnow()
        },
        {
            "restaurant_id": str(restaurant_ids[16]),
            "user_name": "Amit Israeli",
            "rating": 4,
            "comment": "Great vegetarian options! Fresh and healthy",
            "created_at": datetime.utcnow()
        }
    ]
    
    result = db.reviews.insert_many(israeli_reviews)
    print(f"Inserted {len(result.inserted_ids)} reviews")
    print("Israeli restaurant data with expanded cuisines inserted successfully!")

except Exception as e:
    print(f"Error inserting Israeli restaurant data: {e}")
finally:
    client.close()