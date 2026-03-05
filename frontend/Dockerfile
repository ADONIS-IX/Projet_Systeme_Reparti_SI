# Stage 1: Build de l'application React
FROM node:20-alpine AS builder

WORKDIR /app

# Déclaration de l'argument de build
# Jenkins passera la valeur ici (ex: http://localhost:8000/api)
ARG REACT_APP_API_URL

# Définition de la variable d'environnement pour le processus de build Node
ENV REACT_APP_API_URL=$REACT_APP_API_URL

# Copier package.json et package-lock.json
COPY package*.json ./

# Installer les dépendances
RUN npm ci

# Copier le code source
COPY . .

# Build de l'application (utilise la variable ENV définie plus haut)
RUN npm run build

# Stage 2: Servir avec Nginx
FROM nginx:alpine

# Copier les fichiers build depuis le stage précédent
COPY --from=builder /app/build /usr/share/nginx/html

# Exposer le port 80
EXPOSE 80

# Démarrer Nginx
CMD ["nginx", "-g", "daemon off;"]