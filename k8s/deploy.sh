#!/bin/bash
# deploy.sh — Déploiement Kubernetes sans interaction (Windows/Minikube)
set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()  { echo -e "${GREEN}✓ $1${NC}"; }
msg() { echo -e "${YELLOW}▶ $1${NC}"; }
err() { echo -e "${RED}✗ $1${NC}"; exit 1; }

# ── 1. Vérifier Minikube ────────────────────────────────────────────────────
msg "Vérification de Minikube..."
minikube status &>/dev/null || err "Minikube n'est pas démarré. Lancez : minikube start --driver=docker"
ok "Minikube actif"

# ── 2. Pointer Docker vers le daemon Minikube ───────────────────────────────
msg "Configuration de l'environnement Docker (Minikube)..."
eval $(minikube docker-env)
ok "Docker pointé sur Minikube"

# ── 3. Build des images en local dans le daemon Minikube ────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

msg "Build image backend..."
docker build -t adonisdocker/backend:latest "$SCRIPT_DIR/backend"
ok "Image backend construite"

msg "Build image frontend..."
docker build \
  --build-arg REACT_APP_API_URL="/api" \
  -t adonisdocker/frontend:latest "$SCRIPT_DIR/frontend"
ok "Image frontend construite"

# ── 4. Appliquer les manifests Kubernetes ───────────────────────────────────
msg "Application des manifests Kubernetes..."
kubectl apply -f "$SCRIPT_DIR/k8s/secrets.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/postgres-pvc.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/postgres-deployment.yaml"

msg "Attente PostgreSQL..."
kubectl rollout status deployment/postgres --timeout=120s
ok "PostgreSQL prêt"

# ── 5. Job de migration Django ───────────────────────────────────────────────
msg "Suppression de l'ancien Job de migration (si existant)..."
kubectl delete job django-migrate --ignore-not-found=true

msg "Lancement du Job de migration Django..."
kubectl apply -f "$SCRIPT_DIR/k8s/backend-deployment.yaml"

msg "Attente de la fin des migrations..."
kubectl wait --for=condition=complete job/django-migrate --timeout=120s \
  || {
    echo ""
    err "Le Job de migration a échoué. Logs :"
    kubectl logs job/django-migrate
  }
ok "Migrations Django terminées"

# ── 6. Déploiement Backend ───────────────────────────────────────────────────
msg "Attente du Backend..."
kubectl rollout status deployment/backend --timeout=180s
ok "Backend prêt"

# ── 7. Déploiement Frontend ──────────────────────────────────────────────────
kubectl apply -f "$SCRIPT_DIR/k8s/frontend-deployment.yaml"
msg "Attente Frontend..."
kubectl rollout status deployment/frontend --timeout=120s
ok "Frontend prêt"

# ── 8. Résumé ────────────────────────────────────────────────────────────────
MINIKUBE_IP=$(minikube ip)
echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}  Déploiement terminé avec succès ! 🚀  ${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""
echo "  Frontend  →  http://${MINIKUBE_IP}:30080"
echo "  Backend   →  http://${MINIKUBE_IP}:30800/api"
echo ""
echo "Commandes utiles :"
echo "  kubectl get pods"
echo "  kubectl get services"
echo "  kubectl logs -f deployment/backend"
echo "  kubectl logs job/django-migrate"
echo "  minikube dashboard"