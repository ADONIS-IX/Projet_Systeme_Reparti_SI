#!/bin/bash

# Arrêter le script à la moindre erreur
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.." || exit 1

echo "Déploiement Kubernetes"
echo "========================="

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Vérifier Minikube
echo -e "${YELLOW}Vérification de Minikube...${NC}"
if ! minikube status &> /dev/null; then
    echo -e "${RED}Erreur: Minikube n'est pas démarré${NC}"
    echo "Démarrez Minikube avec: minikube start --driver=docker"
    exit 1
fi
echo -e "${GREEN}✓ Minikube est actif${NC}"

# 2. Configurer l'environnement Docker
echo -e "${YELLOW}Configuration de Docker pour Minikube...${NC}"
eval $(minikube docker-env)
echo -e "${GREEN}✓ Docker configuré${NC}"

# 3. Construire les images
echo -e "${YELLOW}Construction des images Docker...${NC}"
if [ -d "./backend" ] && [ -d "./frontend" ]; then
    docker build -t backend:latest ./backend
    docker build -t frontend:latest ./frontend
    echo -e "${GREEN}✓ Images construites${NC}"
else
    echo -e "${RED}Erreur : Les dossiers ./backend ou ./frontend sont introuvables.${NC}"
    exit 1
fi

# 4. Créer ou mettre à jour les secrets
echo -e "${YELLOW}Création/Mise à jour des secrets...${NC}"
read -sp "Mot de passe PostgreSQL: " DB_PASSWORD
echo
kubectl create secret generic db-secret \
  --from-literal=password=$DB_PASSWORD \
  --dry-run=client -o yaml | kubectl apply -f -

read -sp "Django SECRET_KEY: " DJANGO_SECRET
echo
kubectl create secret generic django-secret \
  --from-literal=secret-key=$DJANGO_SECRET \
  --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Secrets créés/mis à jour${NC}"

# 5. Déployer PostgreSQL
echo -e "${YELLOW}Déploiement de PostgreSQL...${NC}"
kubectl apply -f k8s/postgres-pvc.yaml
kubectl apply -f k8s/postgres-deployment.yaml
kubectl rollout status deployment/postgres --timeout=300s

# 6. Déployer Backend
echo -e "${YELLOW}Déploiement du Backend...${NC}"
kubectl apply -f k8s/backend-deployment.yaml
kubectl rollout status deployment/backend --timeout=300s

# 7. Migrations Django
echo -e "${YELLOW}Application des migrations Django...${NC}"
BACKEND_POD=$(kubectl get pods -l app=backend -o jsonpath='{.items[0].metadata.name}')
kubectl exec "$BACKEND_POD" -- python manage.py migrate
echo -e "${GREEN}✓ Migrations appliquées${NC}"

# 8. Déployer Frontend
echo -e "${YELLOW}Déploiement du Frontend...${NC}"
kubectl apply -f k8s/frontend-deployment.yaml
kubectl rollout status deployment/frontend --timeout=300s

# Fin
echo ""
echo -e "${GREEN}=========================${NC}"
echo -e "${GREEN}Déploiement terminé !${NC}"
echo -e "${GREEN}=========================${NC}"
echo ""
echo "Accès aux services :"
echo "-------------------"
echo "Frontend: $(minikube service frontend --url)"
echo "Backend: $(minikube service backend --url)"
echo ""
echo "Commandes utiles :"
echo "- Voir les pods: kubectl get pods"
echo "- Voir les services: kubectl get services"
echo "- Logs backend: kubectl logs -f deployment/backend"
echo "- Logs frontend: kubectl logs -f deployment/frontend"
echo "- Dashboard: minikube dashboard"