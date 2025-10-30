FROM nginx:1.25-alpine

# Remove default nginx configuration
RUN rm -f /etc/nginx/conf.d/default.conf

# Copy our custom configuration
COPY conf.d/restaurant-app.conf /etc/nginx/conf.d/restaurant-app.conf

# Ensure proper permissions
RUN chmod 644 /etc/nginx/conf.d/restaurant-app.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]