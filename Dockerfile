# Dockerfile minimal pour Node
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
ENV PORT=8000
EXPOSE 8000
CMD ["node", "server.js"]