import React from 'react';
import { render, screen, fireEvent, act } from '@testing-library/react';
import RestaurantModal from '../components/RestaurantModal';

// Mock the API with proper response structure
jest.mock('../services/api', () => ({
  restaurantAPI: {
    getReviews: jest.fn().mockResolvedValue({ 
      data: [
        { _id: '1', user_name: 'Test User', rating: 5, comment: 'Great!', created_at: new Date().toISOString() }
      ] 
    }),
    addReview: jest.fn().mockResolvedValue({ data: { success: true } })
  }
}));

// Suppress console errors for cleaner test output
const originalError = console.error;
beforeAll(() => {
  console.error = jest.fn();
});

afterAll(() => {
  console.error = originalError;
});

describe('RestaurantModal', () => {
  const mockRestaurant = {
    _id: '1',
    name: 'Test Restaurant',
    style: 'pizza',
    address: 'Test Address',
    average_rating: 4.5,
    total_reviews: 10,
    description: 'Test description'
  };

  const mockOnClose = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('renders restaurant information', async () => {
    await act(async () => {
      render(<RestaurantModal restaurant={mockRestaurant} onClose={mockOnClose} />);
    });
    expect(screen.getByText('Test Restaurant')).toBeInTheDocument();
  });

  test('closes modal when X button clicked', async () => {
    await act(async () => {
      render(<RestaurantModal restaurant={mockRestaurant} onClose={mockOnClose} />);
    });
    const closeButton = screen.getByText('×');
    fireEvent.click(closeButton);
    expect(mockOnClose).toHaveBeenCalled();
  });
});