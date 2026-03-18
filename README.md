# TP DevOps - Pipeline GitOps locale sécurisée

<p align="center">
  <img src="https://img.shields.io/badge/Rocky%20Linux-10.x-10b981?style=for-the-badge&logo=rockylinux&logoColor=white" alt="Rocky Linux 10.x">
  <img src="https://img.shields.io/badge/Terraform-IaC-7c3aed?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform">
  <img src="https://img.shields.io/badge/Ansible-Automation-ee0000?style=for-the-badge&logo=ansible&logoColor=white" alt="Ansible">
  <img src="https://img.shields.io/badge/Docker-Containers-2496ed?style=for-the-badge&logo=docker&logoColor=white" alt="Docker">
  <img src="https://img.shields.io/github/actions/workflow/status/Kaminokuri/TP-DevOps/ci.yml?branch=main&style=for-the-badge&label=CI" alt="CI GitHub Actions">
</p>

Projet complet de TP DevOps pour Rocky Linux autour d'une pipeline GitOps locale avec Terraform, Ansible, Jenkins, Prometheus, Grafana, Checkov et Trivy.

Ce dépôt est désormais :

- préparé pour Rocky Linux
- déployé localement
- publié sur GitHub
- configuré avec un système d'auto-commit et d'auto-push
- documenté avec les commandes et les actions réalisées de A à Z

## Objectifs

- Déployer une infrastructure locale avec Terraform
- Configurer les services avec Ansible
- Exécuter une pipeline CI/CD avec Jenkins
- Intégrer des contrôles de sécurité IaC et des scans d'images
- Superviser la plateforme avec Prometheus et Grafana
- Publier le projet sur GitHub avec un suivi automatique des changements

## Architecture

La stack déployée contient :

- `prometheus` pour la collecte des métriques
- `grafana` pour la visualisation
- `jenkins` pour la pipeline CI/CD
- `monitoring-app` comme application d'exemple conteneurisée
- un réseau Docker dédié et des volumes persistants

## Arborescence

```text
tp-gitops-local/
├── .github/workflows/ci.yml
├── Jenkinsfile
├── Makefile
├── README.md
├── application/docker/
├── configuration/ansible/
├── infrastructure/terraform/
├── jenkins/
├── monitoring/
├── scripts/
├── security/policies/
└── tests/
```

## Prérequis

- Rocky Linux 10.x
- 4 vCPU minimum
- 8 Go de RAM minimum
- 20 Go d'espace disque
- un accès administrateur sur la machine

Outils attendus :

- `docker`
- `terraform`
- `ansible-playbook`
- `git`
- `python3`
- `pip3`
- `checkov`
- `trivy`
- `curl`

## Installation sur Rocky Linux

Le dépôt fournit un script d'installation :

```bash
chmod +x scripts/install-rocky.sh
sudo ./scripts/install-rocky.sh
```

Ce script installe :

- Git, Python, pip, make et des utilitaires système
- Docker Engine et active le service
- Terraform
- Ansible Core
- Checkov
- Trivy
- un miroir local du provider Docker de Terraform pour contourner les accès limités à `registry.terraform.io`
- un fichier `terraform.rc` généré localement pour forcer Terraform à utiliser ce miroir

## Démarrage rapide

```bash
make bootstrap
cp infrastructure/terraform/terraform.tfvars.example infrastructure/terraform/terraform.tfvars
make validate
make deploy
make setup-jenkins
make test
```

## URL par défaut

- Prometheus : `http://localhost:9090`
- Grafana : `http://localhost:3000`
- Jenkins : `http://localhost:8080`
- Application exemple : `http://localhost:3001`

Identifiants par défaut :

- Grafana : `admin / gitops2026`
- Jenkins : `admin / Admin123!2026`

Pensez à modifier ces secrets dans `infrastructure/terraform/terraform.tfvars`.

## Ce Qui A Été Fait De A à Z

Le projet a été réalisé dans cet ordre, du démarrage à la mise en ligne :

1. Installation des prérequis Rocky Linux avec `scripts/install-rocky.sh`.
2. Préparation du dépôt avec `make bootstrap`.
3. Mise en place du miroir local du provider Docker Terraform avec `scripts/install-terraform-provider-mirror.sh`.
4. Validation de la configuration avec `scripts/validate-gitops.sh`.
5. Déploiement local avec `scripts/deploy-local.sh`.
6. Provisionnement de Prometheus, Grafana, Jenkins et de `monitoring-app` avec Terraform.
7. Configuration de la plateforme avec Ansible.
8. Vérification de Jenkins avec `scripts/setup-jenkins.sh`.
9. Exécution des tests d'infrastructure Python avec `tests/test_infrastructure.py`.
10. Publication du dépôt sur GitHub via `scripts/publish-github.sh`.
11. Correction de l'image Jenkins pour gérer correctement l'architecture et les dépendances locales.
12. Validation complète de la stack avec les tests d'infrastructure et la vérification Jenkins.
13. Publication du dépôt sur GitHub.
14. Mise en place d'un système d'auto-commit et d'auto-push sur chaque modification locale stable.

## Commandes Utilisées De A à Z

Cette section résume les commandes importantes utilisées pendant le TP, dans l'ordre logique de réalisation.

### 1. Installation et préparation de la machine

```bash
chmod +x scripts/install-rocky.sh
sudo ./scripts/install-rocky.sh

make bootstrap
cp infrastructure/terraform/terraform.tfvars.example infrastructure/terraform/terraform.tfvars
```

### 2. Validation initiale du projet

```bash
make validate

./scripts/validate-gitops.sh

terraform -chdir=infrastructure/terraform fmt -check -recursive
terraform -chdir=infrastructure/terraform init -backend=false
terraform -chdir=infrastructure/terraform validate

ansible-playbook -i configuration/ansible/inventory.yml configuration/ansible/playbook.yml --syntax-check
```

### 3. Déploiement local de la plateforme

```bash
make deploy

./scripts/deploy-local.sh

terraform -chdir=infrastructure/terraform apply -auto-approve
ansible-playbook -i configuration/ansible/inventory.yml configuration/ansible/playbook.yml
./scripts/setup-jenkins.sh
```

### 4. Vérification de la plateforme après déploiement

```bash
docker ps

python3 tests/test_infrastructure.py

curl http://localhost:9090/-/healthy
curl http://localhost:3000/api/health
curl http://localhost:8080/login
curl http://localhost:3001/health
```

### 5. Vérification de Terraform et état de la stack

```bash
terraform -chdir=infrastructure/terraform state list
terraform -chdir=infrastructure/terraform plan -no-color
docker logs jenkins
docker logs prometheus
docker logs grafana
docker logs monitoring-app
```

### 6. Tests et validation finale

```bash
python3 tests/test_infrastructure.py
./scripts/setup-jenkins.sh
./scripts/validate-gitops.sh
```

### 7. Publication sur GitHub

```bash
git remote add origin git@github.com:Kaminokuri/TP-DevOps.git
git branch -M main
git add .
git commit -m "Initial commit: GitOps local pipeline"
./scripts/publish-github.sh
git push -u origin main
```

### 8. Auto-commit et auto-push

Le dépôt est configuré pour effectuer des commits et des push automatiques après quelques secondes de stabilité.

Démarrer le service :

```bash
./scripts/start-autocommit-watch.sh
```

Arrêter le service :

```bash
./scripts/stop-autocommit-watch.sh
```

Consulter le journal :

```bash
tail -n 80 .git/autocommit-watch.log
```

Fonctionnement :

- le watcher surveille l'état Git du dépôt
- il attend `4` secondes sans nouvelle modification
- il lance `git add -A`
- il crée un commit automatique horodaté
- il pousse sur `origin/main`

## Corrections Et Ajustements Réalisés

Les ajustements suivants ont été nécessaires pour obtenir une stack fonctionnelle en local :

- adaptation du `jenkins/Dockerfile` pour gérer correctement les architectures `arm64` et `amd64`
- mise à jour de la version Trivy embarquée dans Jenkins vers `0.69.3`
- remplacement de `docker-ce-cli` par `docker.io` dans l'image Jenkins pour éviter un blocage de signature APT sur Debian `trixie`
- correction des permissions de `jenkins_home` au bootstrap et au deploiement
- ajout d'un système local d'auto-commit et d'auto-push avec un service `systemd`
- configuration de l'identité Git locale pour utiliser le compte `Kaminokuri`

## État Final Du TP

État actuellement validé :

- infrastructure et integration : OK
- Jenkins et pipeline locale : OK
- job Jenkins `gitops-local-pipeline` : OK
- tests d'infrastructure Python : OK
- publication GitHub : OK
- auto-commit et auto-push : OK
- identité Git locale `Kaminokuri` : OK

Comportement du scan securite sur cette machine :

- `./scripts/security-scan.sh` execute Checkov localement
- pour Trivy, le script tente d'abord le binaire local avec des depots DB explicites
- si le binaire local echoue encore sur la resolution DNS OCI, le script bascule automatiquement sur le conteneur officiel `aquasec/trivy`
- ce fallback force des DNS publics (`1.1.1.1` et `8.8.8.8`) pour contourner le blocage observe avec `mirror.gcr.io`

## Résumé Chronologique

Pour garder une trace simple, voici le déroulement complet du TP :

1. Installer les outils sur Rocky Linux.
2. Initialiser le projet et les répertoires locaux.
3. Configurer Terraform avec le miroir du provider Docker.
4. Vérifier Terraform et Ansible.
5. Déployer Prometheus, Grafana, Jenkins et l'application exemple.
6. Vérifier les conteneurs, les endpoints HTTP et les tests Python.
7. Corriger les blocages Jenkins liés à l'architecture, à Trivy, à l'interface en ligne de commande Docker et aux permissions.
8. Vérifier que Jenkins démarre et que le job `gitops-local-pipeline` est bien créé.
9. Publier le dépôt sur GitHub.
10. Activer l'auto-commit et l'auto-push via `systemd`.
11. Configurer Git pour committer avec le compte `Kaminokuri`.

## Pipeline Jenkins

Le job Jenkins est configuré automatiquement via Configuration as Code.

Stages du `Jenkinsfile` :

1. récupération du dépôt
2. vérification de la chaîne d'outils
3. scan IaC avec Checkov
4. construction de l'image applicative
5. scan de l'image avec Trivy
6. déploiement Terraform
7. configuration Ansible
8. vérification de l'état de santé des services
9. tests d'intégration Python

## Commandes Utiles

```bash
make bootstrap
make deploy
make validate
make security
make test
make destroy

./scripts/validate-gitops.sh
./scripts/security-scan.sh
./scripts/setup-jenkins.sh
./scripts/publish-github.sh
./scripts/start-autocommit-watch.sh
./scripts/stop-autocommit-watch.sh
```

## Dépannage

Vérifier les services :

```bash
docker ps
docker logs prometheus
docker logs grafana
docker logs jenkins
docker logs monitoring-app
```

Vérifier Terraform :

```bash
terraform -chdir=infrastructure/terraform init
terraform -chdir=infrastructure/terraform validate
terraform -chdir=infrastructure/terraform plan
```

Relancer la configuration :

```bash
ansible-playbook -i configuration/ansible/inventory.yml configuration/ansible/playbook.yml
```

Vérifier Jenkins :

```bash
./scripts/setup-jenkins.sh
```

Vérifier l'auto-push :

```bash
systemctl status autocommit-watch.service
tail -n 80 .git/autocommit-watch.log
git log --oneline -5
git config --local --get-regexp '^user\.(name|email)$'
```

## Références utiles

- Docker Engine : https://docs.docker.com/engine/
- Terraform : https://developer.hashicorp.com/terraform
- Terraform CLI config et miroirs providers : https://developer.hashicorp.com/terraform/cli/config/config-file
- Ansible Core : https://docs.ansible.com/projects/ansible-core/
- Trivy : https://trivy.dev/

---

**Auteur :** Mathéo Fauvel
**GitHub :** [Kaminokuri](https://github.com/Kaminokuri)
