FROM node:18-alpine AS build
WORKDIR /app
COPY app/package*.json ./
RUN npm ci --only=production || npm install --only=production
COPY app/ ./
EXPOSE 3000
CMD ["node", "server.js"]
