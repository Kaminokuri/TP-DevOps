# TP DevOps - Pipeline GitOps locale securisee

<p align="center">
  <img src="https://img.shields.io/badge/Rocky%20Linux-10.x-10b981?style=for-the-badge&logo=rockylinux&logoColor=white" alt="Rocky Linux 10.x">
  <img src="https://img.shields.io/badge/Terraform-IaC-7c3aed?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform">
  <img src="https://img.shields.io/badge/Ansible-Automation-ee0000?style=for-the-badge&logo=ansible&logoColor=white" alt="Ansible">
  <img src="https://img.shields.io/badge/Docker-Containers-2496ed?style=for-the-badge&logo=docker&logoColor=white" alt="Docker">
  <img src="https://img.shields.io/github/actions/workflow/status/Kaminokuri/TP-DevOps/ci.yml?branch=main&style=for-the-badge&label=CI" alt="CI GitHub Actions">
</p>

Projet complet de TP DevOps pour Rocky Linux autour d'une pipeline GitOps locale avec Terraform, Ansible, Jenkins, Prometheus, Grafana, Checkov et Trivy.

Ce depot est maintenant :

- prepare pour Rocky Linux
- deploye localement
- publie sur GitHub
- configure avec un systeme d'auto-commit et d'auto-push
- documente avec les commandes et les actions realisees de A a Z

## Objectifs

- Deployer une infrastructure locale avec Terraform
- Configurer les services avec Ansible
- Executer une pipeline CI/CD avec Jenkins
- Integrer des controles de securite IaC et des scans d'images
- Superviser la plateforme avec Prometheus et Grafana
- Publier le projet sur GitHub avec un suivi automatique des changements

## Architecture

La stack deployee contient :

- `prometheus` pour la collecte des metriques
- `grafana` pour la visualisation
- `jenkins` pour la pipeline CI/CD
- `monitoring-app` comme application d'exemple conteneurisee
- un reseau Docker dedie et des volumes persistants

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

## Prerequis

- Rocky Linux 10.x
- 4 vCPU minimum
- 8 Go de RAM minimum
- 20 Go d'espace disque
- acces administrateur sur la machine

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

Le depot fournit un script d'installation :

```bash
chmod +x scripts/install-rocky.sh
sudo ./scripts/install-rocky.sh
```

Ce script installe :

- Git, Python, pip, make et des utilitaires systeme
- Docker Engine et active le service
- Terraform
- Ansible Core
- Checkov
- Trivy
- un miroir local du provider Docker de Terraform pour contourner les acces limites a `registry.terraform.io`
- un fichier `terraform.rc` genere localement pour forcer Terraform a utiliser ce miroir

## Demarrage Rapide

```bash
make bootstrap
cp infrastructure/terraform/terraform.tfvars.example infrastructure/terraform/terraform.tfvars
make validate
make deploy
make setup-jenkins
make test
```

## URLs par defaut

- Prometheus : `http://localhost:9090`
- Grafana : `http://localhost:3000`
- Jenkins : `http://localhost:8080`
- Application exemple : `http://localhost:3001`

Identifiants par defaut :

- Grafana : `admin / gitops2026`
- Jenkins : `admin / Admin123!2026`

Pensez a modifier ces secrets dans `infrastructure/terraform/terraform.tfvars`.

## Ce Qui A Ete Fait De A a Z

Le projet a ete realise dans cet ordre, du debut a la mise en ligne :

1. Installation des prerequis Rocky Linux avec `scripts/install-rocky.sh`.
2. Preparation du depot avec `make bootstrap`.
3. Mise en place du miroir local du provider Docker Terraform avec `scripts/install-terraform-provider-mirror.sh`.
4. Validation de la configuration avec `scripts/validate-gitops.sh`.
5. Deploiement local avec `scripts/deploy-local.sh`.
6. Provisionnement de Prometheus, Grafana, Jenkins et de `monitoring-app` avec Terraform.
7. Configuration de la plateforme avec Ansible.
8. Verification de Jenkins avec `scripts/setup-jenkins.sh`.
9. Execution des tests d'infrastructure Python avec `tests/test_infrastructure.py`.
10. Publication du depot sur GitHub via `scripts/publish-github.sh`.
11. Correction de l'image Jenkins pour gerer correctement l'architecture et les dependances locales.
12. Validation complete de la stack avec les tests d'infrastructure et la verification Jenkins.
13. Publication du depot sur GitHub.
14. Mise en place d'un systeme d'auto-commit et d'auto-push sur chaque modification locale stable.

## Commandes Utilisees De A a Z

Cette section resume les commandes importantes utilisees pendant le TP, dans l'ordre logique de realisation.

### 1. Installation et preparation de la machine

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

### 3. Deploiement local de la plateforme

```bash
make deploy

./scripts/deploy-local.sh

terraform -chdir=infrastructure/terraform apply -auto-approve
ansible-playbook -i configuration/ansible/inventory.yml configuration/ansible/playbook.yml
./scripts/setup-jenkins.sh
```

### 4. Verification de la plateforme apres deploiement

```bash
docker ps

python3 tests/test_infrastructure.py

curl http://localhost:9090/-/healthy
curl http://localhost:3000/api/health
curl http://localhost:8080/login
curl http://localhost:3001/health
```

### 5. Verification de Terraform et etat de la stack

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

Le depot est configure pour commit et push automatiques apres quelques secondes de stabilite.

Demarrer le service :

```bash
./scripts/start-autocommit-watch.sh
```

Arreter le service :

```bash
./scripts/stop-autocommit-watch.sh
```

Consulter le journal :

```bash
tail -n 80 .git/autocommit-watch.log
```

Fonctionnement :

- le watcher surveille l'etat Git du depot
- il attend `4` secondes sans nouvelle modification
- il lance `git add -A`
- il cree un commit automatique horodate
- il pousse sur `origin/main`

## Corrections Et Ajustements Realises

Les ajustements suivants ont ete necessaires pour obtenir une stack fonctionnelle en local :

- adaptation du `jenkins/Dockerfile` pour gerer correctement les architectures `arm64` et `amd64`
- mise a jour de la version Trivy embarquee dans Jenkins vers `0.69.3`
- remplacement de `docker-ce-cli` par `docker.io` dans l'image Jenkins pour eviter un blocage de signature APT sur Debian `trixie`
- correction des permissions de `jenkins_home` au bootstrap et au deploiement
- ajout d'un systeme local d'auto-commit et d'auto-push avec un service `systemd`
- configuration de l'identite Git locale pour utiliser le compte `Kaminokuri`

## Etat Final Du TP

Etat actuellement valide :

- infrastructure et integration : OK
- Jenkins et pipeline locale : OK
- job Jenkins `gitops-local-pipeline` : OK
- tests d'infrastructure Python : OK
- publication GitHub : OK
- auto-commit et auto-push : OK
- identite Git locale `Kaminokuri` : OK

Point encore limite par l'environnement :

- `./scripts/security-scan.sh` lance bien les etapes Checkov
- la partie Trivy echoue sur le telechargement de la base de vulnerabilites
- cause observee : resolution DNS indisponible pour `mirror.gcr.io` sur cette machine

Exemple d'erreur observee :

```text
lookup mirror.gcr.io on 192.168.70.2:53: no such host
```

Conclusion :

- le projet fonctionne de bout en bout pour le deploiement, Jenkins, les tests et GitHub
- le blocage restant vient du reseau de l'environnement, pas de la logique Terraform, Ansible ou Jenkins

## Resume Chronologique

Pour garder une trace simple, voici le scenario complet du TP :

1. Installer les outils sur Rocky Linux.
2. Initialiser le projet et les repertoires locaux.
3. Configurer Terraform avec le miroir du provider Docker.
4. Verifier Terraform et Ansible.
5. Deployer Prometheus, Grafana, Jenkins et l'application exemple.
6. Verifier les conteneurs, les endpoints HTTP et les tests Python.
7. Corriger les blocages Jenkins lies a l'architecture, a Trivy, a la CLI Docker et aux permissions.
8. Verifier que Jenkins demarre et que le job `gitops-local-pipeline` est bien cree.
9. Publier le depot sur GitHub.
10. Activer l'auto-commit et l'auto-push via `systemd`.
11. Configurer Git pour committer avec le compte `Kaminokuri`.

## Pipeline Jenkins

Le job Jenkins est configure automatiquement via Configuration as Code.

Stages du `Jenkinsfile` :

1. checkout du depot
2. verification de la toolchain
3. scan IaC avec Checkov
4. build de l'image applicative
5. scan de l'image avec Trivy
6. deploiement Terraform
7. configuration Ansible
8. health checks
9. tests d'integration Python

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

## Depannage

Verifier les services :

```bash
docker ps
docker logs prometheus
docker logs grafana
docker logs jenkins
docker logs monitoring-app
```

Verifier Terraform :

```bash
terraform -chdir=infrastructure/terraform init
terraform -chdir=infrastructure/terraform validate
terraform -chdir=infrastructure/terraform plan
```

Rejouer la configuration :

```bash
ansible-playbook -i configuration/ansible/inventory.yml configuration/ansible/playbook.yml
```

Verifier Jenkins :

```bash
./scripts/setup-jenkins.sh
```

Verifier l'auto-push :

```bash
systemctl status autocommit-watch.service
tail -n 80 .git/autocommit-watch.log
git log --oneline -5
git config --local --get-regexp '^user\.(name|email)$'
```

## References Utiles

- Docker Engine : https://docs.docker.com/engine/
- Terraform : https://developer.hashicorp.com/terraform
- Terraform CLI config et miroirs providers : https://developer.hashicorp.com/terraform/cli/config/config-file
- Ansible Core : https://docs.ansible.com/projects/ansible-core/
- Trivy : https://trivy.dev/

---

**Auteur :** Mathéo Fauvel
**GitHub :** [Kaminokuri](https://github.com/Kaminokuri)
**Site du wiki :** [wiki.matheo-fauvel.fr](https://wiki.matheo-fauvel.fr)