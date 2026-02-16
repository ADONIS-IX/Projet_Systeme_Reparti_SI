# Stage 1: Build de l'application React
FROM node:20-alpine AS builder

WORKDIR /app

# Copier package.json et package-lock.json
COPY package*.json ./

# Installer les dépendances
RUN npm ci

# Copier le code source
COPY . .

# Build de l'application
RUN npm run build

# Stage 2: Servir avec Nginx
FROM nginx:alpine

# Copier les fichiers build depuis le stage précédent
COPY --from=builder /app/build /usr/share/nginx/html

# Copier la configuration Nginx personnalisée (optionnel)
# COPY nginx.conf /etc/nginx/conf.d/default.conf

# Exposer le port 80
EXPOSE 80

# Démarrer Nginx
CMD ["nginx", "-g", "daemon off;"]