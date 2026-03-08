# Documentation — Système Réparti

Ce dossier contient la documentation du projet :

- **Rapport de synthèse** (PDF, 10 pages max) : introduction, architecture, screenshots, pipeline CI/CD.
- **Schéma d'architecture** : diagramme des composants (Frontend ↔ Backend ↔ PostgreSQL).

## Architecture cible

```
┌──────────────┐      ┌──────────────────┐      ┌─────────────┐
│   Frontend   │      │   Backend        │      │ PostgreSQL  │
│   (React)    │─────▶│   (Django REST)  │─────▶│   17        │
│   Nginx :80  │ /api │   Gunicorn :8000 │      │   :5432     │
└──────────────┘      └──────────────────┘      └─────────────┘
```

## Technologies

| Composant        | Technologie            |
| ---------------- | ---------------------- |
| Frontend         | React 19, Bootstrap 5  |
| Backend          | Django 5, DRF          |
| Base de données  | PostgreSQL 17          |
| Conteneurisation | Docker, Docker Compose |
| Orchestration    | Kubernetes (Minikube)  |
| Automatisation   | Ansible                |
| CI/CD            | Jenkins                |

## Déploiement

Voir le [README principal](../README.md) ou utiliser :

- **Docker Compose** : `docker compose up --build`
- **Kubernetes** : `bash k8s/deploy.sh`
- **Ansible** : `ansible-playbook ansible/playbook.yml`
