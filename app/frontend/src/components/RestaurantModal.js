// Updated RestaurantModal.js - Centered overlay modal
import React, { useState, useEffect } from 'react';
import { restaurantAPI } from '../services/api';

const RestaurantModal = ({ restaurant, onClose }) => {
  const [reviews, setReviews] = useState([]);
  const [newReview, setNewReview] = useState({ user_name: '', rating: 5, comment: '' });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (restaurant) {
      fetchReviews();
    }
  }, [restaurant]);

  const fetchReviews = async () => {
    try {
      const response = await restaurantAPI.getReviews(restaurant._id);
      setReviews(response.data);
    } catch (error) {
      console.error('Error fetching reviews:', error);
    }
  };

  const handleSubmitReview = async (e) => {
    e.preventDefault();
    if (!newReview.user_name.trim()) return;

    setLoading(true);
    try {
      await restaurantAPI.addReview(restaurant._id, newReview);
      setNewReview({ user_name: '', rating: 5, comment: '' });
      fetchReviews();
      // Close modal after successful review submission
      onClose();
    } catch (error) {
      console.error('Error adding review:', error);
    } finally {
      setLoading(false);
    }
  };

  // Helper function to get display name
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

  // Handle click on backdrop (outside modal)
  const handleBackdropClick = (e) => {
    if (e.target === e.currentTarget) {
      onClose();
    }
  };

  if (!restaurant) return null;

  return (
    <div 
      className="modal-overlay"
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: 'rgba(0, 0, 0, 0.5)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 1000,
        padding: '20px'
      }}
      onClick={handleBackdropClick}
    >
      <div 
        className="modal-content"
        style={{
          backgroundColor: 'white',
          borderRadius: '12px',
          maxWidth: '600px',
          width: '100%',
          maxHeight: '80vh',
          overflowY: 'auto',
          boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
          animation: 'modalSlideIn 0.3s ease-out'
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div style={{ padding: '24px 24px 0 24px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '16px' }}>
            <h2 style={{ fontSize: '24px', fontWeight: 'bold', color: '#1f2937', margin: 0 }}>
              {restaurant.name}
            </h2>
            <button 
              onClick={onClose}
              style={{
                background: 'none',
                border: 'none',
                fontSize: '24px',
                color: '#6b7280',
                cursor: 'pointer',
                padding: '4px',
                lineHeight: 1
              }}
            >
              ×
            </button>
          </div>

          <p style={{ color: '#3b82f6', fontWeight: '600', margin: '0 0 8px 0' }}>
            {getCategoryDisplayName(restaurant.style)}
          </p>
          <p style={{ color: '#374151', margin: '0 0 12px 0' }}>
            {restaurant.address}
          </p>
          
          <div style={{ display: 'flex', alignItems: 'center', marginBottom: '16px' }}>
            <span style={{ color: '#fbbf24', marginRight: '8px' }}>⭐</span>
            <span style={{ fontWeight: '600', color: '#1f2937' }}>
              {restaurant.average_rating || 'No ratings'}
            </span>
            <span style={{ marginLeft: '8px', color: '#6b7280' }}>
              ({restaurant.total_reviews || 0} reviews)
            </span>
          </div>
          
          {restaurant.description && (
            <p style={{ color: '#374151', lineHeight: '1.5', margin: '0 0 24px 0' }}>
              {restaurant.description}
            </p>
          )}
        </div>

        {/* Add Review Section */}
        <div style={{ padding: '0 24px', borderTop: '1px solid #e5e7eb' }}>
          <h3 style={{ fontSize: '18px', fontWeight: '600', margin: '24px 0 16px 0', color: '#1f2937' }}>
            Add Review
          </h3>
          <form onSubmit={handleSubmitReview}>
            <div style={{ marginBottom: '16px' }}>
              <input
                type="text"
                placeholder="Your name"
                value={newReview.user_name}
                onChange={(e) => setNewReview({ ...newReview, user_name: e.target.value })}
                style={{
                  width: '100%',
                  padding: '12px',
                  border: '1px solid #d1d5db',
                  borderRadius: '6px',
                  fontSize: '14px'
                }}
                required
              />
            </div>
            <div style={{ marginBottom: '16px' }}>
              <select
                value={newReview.rating}
                onChange={(e) => setNewReview({ ...newReview, rating: parseInt(e.target.value) })}
                style={{
                  width: '100%',
                  padding: '12px',
                  border: '1px solid #d1d5db',
                  borderRadius: '6px',
                  fontSize: '14px'
                }}
              >
                {[5, 4, 3, 2, 1].map(rating => (
                  <option key={rating} value={rating}>
                    {rating} Star{rating !== 1 ? 's' : ''}
                  </option>
                ))}
              </select>
            </div>
            <div style={{ marginBottom: '16px' }}>
              <textarea
                placeholder="Your review (optional)"
                value={newReview.comment}
                onChange={(e) => setNewReview({ ...newReview, comment: e.target.value })}
                style={{
                  width: '100%',
                  padding: '12px',
                  border: '1px solid #d1d5db',
                  borderRadius: '6px',
                  fontSize: '14px',
                  height: '80px',
                  resize: 'vertical'
                }}
              />
            </div>
            <button
              type="submit"
              disabled={loading}
              style={{
                backgroundColor: loading ? '#9ca3af' : '#3b82f6',
                color: 'white',
                padding: '12px 24px',
                borderRadius: '6px',
                border: 'none',
                cursor: loading ? 'not-allowed' : 'pointer',
                fontSize: '14px',
                fontWeight: '500',
                marginBottom: '24px'
              }}
            >
              {loading ? 'Adding...' : 'Add Review'}
            </button>
          </form>
        </div>

        {/* Reviews Section */}
        <div style={{ padding: '0 24px 24px 24px', borderTop: '1px solid #e5e7eb' }}>
          <h3 style={{ fontSize: '18px', fontWeight: '600', margin: '24px 0 16px 0', color: '#1f2937' }}>
            Reviews ({reviews.length})
          </h3>
          {reviews.length === 0 ? (
            <p style={{ color: '#6b7280', fontStyle: 'italic' }}>No reviews yet.</p>
          ) : (
            <div>
              {reviews.map(review => (
                <div key={review._id} style={{ marginBottom: '16px', paddingBottom: '16px', borderBottom: '1px solid #f3f4f6' }}>
                  <div style={{ display: 'flex', alignItems: 'center', marginBottom: '8px' }}>
                    <span style={{ fontWeight: '500', color: '#1f2937' }}>
                      {review.user_name}
                    </span>
                    <span style={{ marginLeft: '12px', color: '#fbbf24' }}>
                      {'⭐'.repeat(review.rating)}
                    </span>
                    <span style={{ marginLeft: '12px', color: '#6b7280', fontSize: '12px' }}>
                      {new Date(review.created_at).toLocaleDateString()}
                    </span>
                  </div>
                  {review.comment && (
                    <p style={{ color: '#374151', margin: 0, lineHeight: '1.5' }}>
                      {review.comment}
                    </p>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      <style jsx>{`
        @keyframes modalSlideIn {
          from {
            opacity: 0;
            transform: scale(0.9) translateY(-20px);
          }
          to {
            opacity: 1;
            transform: scale(1) translateY(0);
          }
        }
      `}</style>
    </div>
  );
};

export default RestaurantModal;