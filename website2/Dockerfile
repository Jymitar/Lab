# Use the nginx:alpine image as the base image
FROM nginx:alpine

# Copy the index.html file into the container's default HTML directory
COPY index.html /usr/share/nginx/html/index.html

# Set NGINX_PORT environment variable to default 8080
ENV NGINX_PORT=8080

# Expose the NGINX_PORT port
EXPOSE $NGINX_PORT

# Start the Nginx server
CMD ["nginx", "-g", "daemon off;"]