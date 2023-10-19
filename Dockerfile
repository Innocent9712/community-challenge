# Start with a suitable base image
FROM node:14 AS builder

# Stage 1: Build the Vue.js frontend
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY src ./src
COPY public ./public
COPY .env ./.env
COPY babel.config.js ./babel.config.js
COPY jsconfig.json ./jsconfig.json
COPY vue.config.js ./vue.config.js
RUN npm run build

# Stage 2: Build the Python backend
FROM python:3.8 AS backend
WORKDIR /app

COPY requirements.txt ./
RUN pip install -r requirements.txt
COPY main.py .

# Stage 3: Create the final container
FROM nginx:alpine

# Install supervisord
RUN apk add --no-cache supervisor

# Copy supervisord configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built Vue.js frontend from the "builder" stage
COPY --from=builder /app/dist /app/dist
COPY --from=backend /app/requirements.txt /app/requirements.txt
COPY --from=backend /app/main.py /app/main.py

# Copy Python dependencies and binary from the "backend" stage
COPY --from=backend /usr/local /usr/local

ENV FLASK_APP=/app/main.py
ENV FLASK_ENV=development

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
