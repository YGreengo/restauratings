import React, { useState, useEffect } from 'react';
import Map from './components/Map';
import RestaurantList from './components/RestaurantList';
import RestaurantModal from './components/RestaurantModal';
import { restaurantAPI } from './services/api';
import './App.css';

function App() {
  const [restaurants, setRestaurants] = useState([]);
  const [categories, setCategories] = useState([]);
  const [selectedCategory, setSelectedCategory] = useState(null);
  const [selectedRestaurant, setSelectedRestaurant] = useState(null);
  const [loading, setLoading] = useState(true);
  const [userLocation, setUserLocation] = useState(null);
  const [viewMode, setViewMode] = useState('categories'); // 'categories' or 'restaurants'

  useEffect(() => {
    fetchCategories();
    getUserLocation();
  }, []);

  const fetchCategories = async () => {
    setLoading(true);
    try {
      const response = await restaurantAPI.getRestaurants();
      const allRestaurants = response.data;
      
      // Group restaurants by cuisine type
      const categoryMap = {};
      allRestaurants.forEach(restaurant => {
        const style = restaurant.style;
        if (!categoryMap[style]) {
          categoryMap[style] = {
            category: style,
            count: 0,
            restaurants: [],
            // Use average coordinates for category center
            avgLat: 0,
            avgLng: 0
          };
        }
        categoryMap[style].count++;
        categoryMap[style].restaurants.push(restaurant);
        categoryMap[style].avgLat += restaurant.latitude;
        categoryMap[style].avgLng += restaurant.longitude;
      });

      // Calculate average coordinates for each category
      const categoriesArray = Object.values(categoryMap).map(cat => ({
        ...cat,
        avgLat: cat.avgLat / cat.count,
        avgLng: cat.avgLng / cat.count
      }));

      setCategories(categoriesArray);
      setRestaurants([]);
    } catch (error) {
      console.error('Error fetching categories:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchRestaurantsByCategory = async (categoryName) => {
    setLoading(true);
    try {
      const response = await restaurantAPI.getRestaurants({ style: categoryName });
      setRestaurants(response.data);
      setSelectedCategory(categoryName);
      setViewMode('restaurants');
    } catch (error) {
      console.error('Error fetching restaurants:', error);
    } finally {
      setLoading(false);
    }
  };

  const getUserLocation = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setUserLocation({
            lat: position.coords.latitude,
            lng: position.coords.longitude
          });
        },
        (error) => {
          console.error('Error getting location:', error);
          // Default to Tel Aviv if geolocation fails
          setUserLocation({ lat: 32.0853, lng: 34.7818 });
        }
      );
    } else {
      // Default to Tel Aviv
      setUserLocation({ lat: 32.0853, lng: 34.7818 });
    }
  };

  const handleBackToCategories = () => {
    setViewMode('categories');
    setSelectedCategory(null);
    setRestaurants([]);
    fetchCategories();
  };

  const handleCategorySelect = (category) => {
    fetchRestaurantsByCategory(category.category);
  };

  const handleRestaurantSelect = (restaurant) => {
    setSelectedRestaurant(restaurant);
  };

  return (
    <div className="App">
      <header className="bg-blue-600 text-white p-4">
        <div className="flex items-center justify-center">
          <h1 className="text-2xl font-bold">Restauratings</h1>
        </div>
      </header>

      {viewMode === 'categories' && (
        <div className="info-bar bg-gray-100 p-4">
          <p className="text-gray-700">
            Click on a cuisine category marker to explore restaurants of that type
          </p>
        </div>
      )}

      {viewMode === 'restaurants' && (
        <div className="filters bg-gray-100 p-4 flex gap-4 items-center justify-between">
          <button
            onClick={handleBackToCategories}
            className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-700 transition-colors"
          >
            ← Back to Categories
          </button>
          <span className="font-semibold text-gray-700">
            Showing: {getCategoryDisplayName(selectedCategory)} ({restaurants.length} restaurants)
          </span>
          <button
            onClick={() => fetchRestaurantsByCategory(selectedCategory)}
            className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
          >
            Refresh
          </button>
        </div>
      )}

      <div className="main-content flex" style={{ height: 'calc(100vh - 140px)' }}>
        <div className="sidebar w-1/3 bg-gray-50 overflow-y-auto">
          {loading ? (
            <div className="p-4">Loading...</div>
          ) : viewMode === 'categories' ? (
            <CategoryList
              categories={categories}
              onCategorySelect={handleCategorySelect}
            />
          ) : (
            <RestaurantList
              restaurants={restaurants}
              onRestaurantSelect={handleRestaurantSelect}
            />
          )}
        </div>

        <div className="map-container w-2/3">
          {userLocation && (
            <Map
              restaurants={viewMode === 'restaurants' ? restaurants : []}
              categories={viewMode === 'categories' ? categories : []}
              viewMode={viewMode}
              onRestaurantSelect={handleRestaurantSelect}
              onCategorySelect={handleCategorySelect}
              center={userLocation}
            />
          )}
        </div>
      </div>

      {selectedRestaurant && (
        <RestaurantModal
          restaurant={selectedRestaurant}
          onClose={() => setSelectedRestaurant(null)}
        />
      )}
    </div>
  );
}

// Helper function to get display name for categories
const getCategoryDisplayName = (category) => {
  const displayNames = {
    'pizza': 'Pizza',
    'burger': 'Burger',
    'israeli': 'Israeli',
    'cafe': 'Cafe',
    'pita': 'Pita',
    'high_cuisine': 'High Cuisine',
    'italian': 'Italian',
    'asian': 'Asian',
    'vegetarian': 'Vegetarian',
    'bakery': 'Bakery'
  };
  return displayNames[category] || category;
};

// Helper function to get category colors (matching map colors)
const getCategoryColor = (category) => {
  const colorMap = {
    'pizza': '#e74c3c',        // Red
    'burger': '#f39c12',       // Orange  
    'israeli': '#3498db',      // Blue
    'cafe': '#9b59b6',         // Purple
    'pita': '#27ae60',         // Green
    'high_cuisine': '#8e44ad',  // Dark Purple
    'italian': '#e67e22',      // Dark Orange
    'asian': '#f1c40f',        // Yellow
    'vegetarian': '#2ecc71',   // Light Green
    'bakery': '#d35400'        // Brown
  };
  return colorMap[category] || '#17a2b8';
};

// New CategoryList component
const CategoryList = ({ categories, onCategorySelect }) => {
  if (!categories.length) {
    return <div className="p-4">No categories found.</div>;
  }

  return (
    <div className="category-list p-4">
      <h2 className="text-xl font-bold mb-4 text-center">Cuisine Categories ({categories.length})</h2>
      {categories.map((category, index) => {
        const displayName = getCategoryDisplayName(category.category);
        const categoryColor = getCategoryColor(category.category);
        return (
          <div 
            key={index}
            className="category-card bg-white p-4 mb-4 rounded-lg shadow cursor-pointer transition-all duration-200 border-l-4 hover:bg-gray-50 hover:shadow-xl hover:scale-105 active:scale-100"
            style={{ 
              borderLeftColor: categoryColor,
              position: 'relative'
            }}
            onClick={() => onCategorySelect(category)}
          >
            {/* Decorative circles positioned absolutely */}
            <div 
              style={{ 
                position: 'absolute',
                left: '24px',
                top: '50%',
                width: '12px',
                height: '12px',
                borderRadius: '50%',
                backgroundColor: categoryColor,
                transform: 'translateY(-50%)'
              }}
            ></div>
            <div 
              style={{ 
                position: 'absolute',
                right: '24px',
                top: '50%',
                width: '12px',
                height: '12px',
                borderRadius: '50%',
                backgroundColor: categoryColor,
                transform: 'translateY(-50%)'
              }}
            ></div>
            
            {/* Centered content */}
            <div style={{ textAlign: 'center' }}>
              <h3 className="text-lg font-semibold text-gray-800 transition-colors duration-200 hover:text-blue-600" style={{ marginBottom: '8px' }}>
                {displayName}
              </h3>
              <p className="text-gray-600 text-sm" style={{ marginBottom: '4px' }}>
                {category.count} restaurant{category.count !== 1 ? 's' : ''}
              </p>
              <p className="text-xs text-gray-500">
                Click to explore {displayName.toLowerCase()} restaurants
              </p>
            </div>
          </div>
        );
      })}
    </div>
  );
};

export default App;