import '@testing-library/jest-dom';

// Mock Google Maps
global.google = {
  maps: {
    Map: jest.fn(() => ({})),
    Marker: jest.fn(() => ({})),
    InfoWindow: jest.fn(() => ({})),
    event: {
      addListener: jest.fn(),
      removeListener: jest.fn()
    },
    LatLngBounds: jest.fn(() => ({
      extend: jest.fn(),
      isEmpty: jest.fn(() => false)
    })),
    SymbolPath: {
      CIRCLE: 0,
      BACKWARD_CLOSED_ARROW: 1
    }
  }
};

// Mock window.google for map components
Object.defineProperty(window, 'google', {
  value: global.google
});