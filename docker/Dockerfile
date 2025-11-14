FROM node:18-alpine AS build

WORKDIR /app

# Copy package.json & package-lock.json from root
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production || npm install --only=production

# Copy all project files
COPY . .

EXPOSE 3000
CMD ["node", "server.js"]
