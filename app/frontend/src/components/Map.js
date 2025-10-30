// Updated Map.js with category support and proper display names
import React, { useState, useEffect, useCallback } from 'react';
import { Wrapper, Status } from '@googlemaps/react-wrapper';

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

const MapComponent = ({ 
  restaurants, 
  categories, 
  viewMode, 
  onRestaurantSelect, 
  onCategorySelect, 
  center, 
  zoom = 8 
}) => {
  const [map, setMap] = useState(null);
  const [markers, setMarkers] = useState([]);

  const onLoad = useCallback((map) => {
    setMap(map);
  }, []);

  useEffect(() => {
    if (!map) return;

    // Clear existing markers
    markers.forEach(marker => marker.setMap(null));

    let newMarkers = [];

    if (viewMode === 'categories') {
      // Show category markers
      newMarkers = categories.map((category, index) => {
        const displayName = getCategoryDisplayName(category.category);
        const marker = new window.google.maps.Marker({
          position: { lat: category.avgLat, lng: category.avgLng },
          map: map,
          title: `${displayName} (${category.count} restaurants)`,
          icon: {
            path: window.google.maps.SymbolPath.CIRCLE,
            scale: 15 + (category.count * 2), // Size based on restaurant count
            fillColor: getCategoryColor(category.category),
            fillOpacity: 0.8,
            strokeColor: '#ffffff',
            strokeWeight: 2
          }
        });

        const infoWindow = new window.google.maps.InfoWindow({
          content: `
            <div style="padding: 10px; max-width: 200px; text-align: center;">
              <h3 style="margin: 0 0 10px 0; color: #1f2937;">${displayName}</h3>
              <p style="margin: 0 0 10px 0; color: #6b7280;">${category.count} restaurant${category.count !== 1 ? 's' : ''}</p>
              <button 
                onclick="window.selectCategory('${category.category}')" 
                style="background: #3b82f6; color: white; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer; font-size: 14px;"
              >
                Explore ${displayName}
              </button>
            </div>
          `,
        });

        marker.addListener('click', () => {
          infoWindow.open(map, marker);
        });

        return marker;
      });

      // Global function for category selection
      window.selectCategory = (categoryName) => {
        const category = categories.find(c => c.category === categoryName);
        if (category && onCategorySelect) {
          onCategorySelect(category);
        }
      };

    } else if (viewMode === 'restaurants') {
      // Show restaurant markers
      newMarkers = restaurants.map(restaurant => {
        const restaurantDisplayStyle = getCategoryDisplayName(restaurant.style);
        const marker = new window.google.maps.Marker({
          position: { lat: restaurant.latitude, lng: restaurant.longitude },
          map: map,
          title: restaurant.name,
          icon: {
            path: window.google.maps.SymbolPath.BACKWARD_CLOSED_ARROW,
            scale: 6,
            fillColor: getRestaurantColor(restaurant.style),
            fillOpacity: 0.9,
            strokeColor: '#ffffff',
            strokeWeight: 1
          }
        });

        const infoWindow = new window.google.maps.InfoWindow({
          content: `
            <div style="padding: 10px; max-width: 250px;">
              <h3 style="margin: 0 0 8px 0; color: #1f2937;">${restaurant.name}</h3>
              <p style="margin: 0 0 5px 0; color: #3b82f6; font-weight: 600;">${restaurantDisplayStyle}</p>
              <p style="margin: 0 0 8px 0; color: #6b7280; font-size: 14px;">${restaurant.address}</p>
              <div style="display: flex; align-items: center; margin-bottom: 10px;">
                <span style="color: #fbbf24; margin-right: 5px;">⭐</span>
                <span style="font-weight: 600;">${restaurant.average_rating || 'No ratings'}</span>
                <span style="margin-left: 8px; color: #6b7280; font-size: 14px;">(${restaurant.total_reviews || 0} reviews)</span>
              </div>
              <button 
                onclick="window.selectRestaurant('${restaurant._id}')" 
                style="background: #10b981; color: white; border: none; padding: 6px 12px; border-radius: 4px; cursor: pointer; font-size: 13px;"
              >
                View Details
              </button>
            </div>
          `,
        });

        marker.addListener('click', () => {
          infoWindow.open(map, marker);
        });

        return marker;
      });

      // Global function for restaurant selection
      window.selectRestaurant = (id) => {
        const restaurant = restaurants.find(r => r._id === id);
        if (restaurant && onRestaurantSelect) {
          onRestaurantSelect(restaurant);
        }
      };
    }

    setMarkers(newMarkers);

  }, [map, restaurants, categories, viewMode, onRestaurantSelect, onCategorySelect]);

  // Adjust map bounds based on content
  useEffect(() => {
    if (!map || (!restaurants.length && !categories.length)) return;

    const bounds = new window.google.maps.LatLngBounds();

    if (viewMode === 'categories') {
      categories.forEach(category => {
        bounds.extend({ lat: category.avgLat, lng: category.avgLng });
      });
    } else {
      restaurants.forEach(restaurant => {
        bounds.extend({ lat: restaurant.latitude, lng: restaurant.longitude });
      });
    }

    if (!bounds.isEmpty()) {
      map.fitBounds(bounds);
      // Limit zoom level
      const listener = window.google.maps.event.addListener(map, 'bounds_changed', () => {
        if (map.getZoom() > 15) map.setZoom(15);
        window.google.maps.event.removeListener(listener);
      });
    }
  }, [map, restaurants, categories, viewMode]);

  return (
    <div style={{ height: '100%', width: '100%' }} ref={(node) => {
      if (node && !map) {
        const newMap = new window.google.maps.Map(node, {
          center: center || { lat: 32.0853, lng: 34.7818 }, // Default to Tel Aviv
          zoom: zoom,
          styles: [
            {
              featureType: "poi",
              elementType: "labels",
              stylers: [{ visibility: "off" }]
            }
          ]
        });
        onLoad(newMap);
      }
    }} />
  );
};

// Helper function to get category colors
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

// Helper function to get restaurant colors
const getRestaurantColor = (style) => {
  return getCategoryColor(style);
};

const Map = (props) => {
  const render = (status) => {
    switch (status) {
      case Status.LOADING:
        return <div className="flex items-center justify-center h-full">Loading map...</div>;
      case Status.FAILURE:
        return <div className="flex items-center justify-center h-full text-red-600">Error loading map</div>;
      case Status.SUCCESS:
        return <MapComponent {...props} />;
      default:
        return null;
    }
  };

  return (
    <Wrapper 
      apiKey={process.env.REACT_APP_GOOGLE_MAPS_API_KEY} 
      render={render}
      libraries={['places']}
    />
  );
};

export default Map;