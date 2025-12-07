FROM nginx:alpine

# Copy nginx configuration
COPY containers/web/nginx.conf /etc/nginx/conf.d/default.conf

# Copy the static index page
COPY containers/web/index.html /usr/share/nginx/html/index.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
