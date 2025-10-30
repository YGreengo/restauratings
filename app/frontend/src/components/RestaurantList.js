import React from 'react';

const RestaurantList = ({ restaurants, onRestaurantSelect }) => {
  if (!restaurants.length) {
    return <div className="p-4">No restaurants found.</div>;
  }

  return (
    <div className="restaurant-list p-4">
      <h2 className="text-xl font-bold mb-4">Restaurants ({restaurants.length})</h2>
      {restaurants.map(restaurant => (
        <div 
          key={restaurant._id} 
          className="restaurant-card bg-white p-4 mb-4 rounded-lg shadow cursor-pointer hover:shadow-lg transition-shadow"
          onClick={() => onRestaurantSelect(restaurant)}
        >
          <h3 className="text-lg font-semibold">{restaurant.name}</h3>
          <p className="text-gray-600">{restaurant.style}</p>
          <p className="text-sm text-gray-500">{restaurant.address}</p>
          <div className="flex items-center mt-2">
            <span className="text-yellow-500">⭐</span>
            <span className="ml-1">{restaurant.average_rating || 'No ratings'}</span>
            <span className="ml-2 text-gray-500">({restaurant.total_reviews || 0} reviews)</span>
          </div>
        </div>
      ))}
    </div>
  );
};

export default RestaurantList;