import React from 'react';
import { render, screen, act } from '@testing-library/react';
import App from './App';

// Mock the API with proper response
jest.mock('./services/api', () => ({
  restaurantAPI: {
    getRestaurants: jest.fn().mockResolvedValue({ 
      data: [
        { _id: '1', name: 'Test Pizza', style: 'pizza', latitude: 32.0853, longitude: 34.7818, average_rating: 4.5, total_reviews: 10 }
      ] 
    })
  }
}));

// Mock the Map component
jest.mock('./components/Map', () => {
  return function MockMap() {
    return <div data-testid="map">Mock Map</div>;
  };
});

// Suppress console errors for cleaner test output
const originalError = console.error;
beforeAll(() => {
  console.error = jest.fn();
});

afterAll(() => {
  console.error = originalError;
});

test('renders app title', async () => {
  await act(async () => {
    render(<App />);
  });
  expect(screen.getByText('Restauratings')).toBeInTheDocument();
});
