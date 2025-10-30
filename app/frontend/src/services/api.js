import axios from 'axios';

// Since nginx proxies everything, API calls are relative
const API_BASE_URL = '';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const restaurantAPI = {
  getRestaurants: (params = {}) => {
    return api.get('/api/restaurants', { params });
  },

  getRestaurant: (id) => {
    return api.get(`/api/restaurants/${id}`);
  },

  addRestaurant: (data) => {
    return api.post('/api/restaurants', data);
  },

  addReview: (restaurantId, data) => {
    return api.post(`/api/restaurants/${restaurantId}/reviews`, data);
  },

  getReviews: (restaurantId) => {
    return api.get(`/api/restaurants/${restaurantId}/reviews`);
  },
};

export default api;