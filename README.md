# TP DevOps - Pipeline GitOps locale securisee

Projet complet de TP DevOps pour Rocky Linux autour d'une pipeline GitOps locale avec Terraform, Ansible, Jenkins, Prometheus, Grafana, Checkov et Trivy.

Le depot est pret pour une publication GitHub et pour un deploiement local sur une machine Rocky Linux disposant de Docker.

## Objectifs

- Deployer une infrastructure locale avec Terraform
- Configurer les services avec Ansible
- Executer une pipeline CI/CD avec Jenkins
- Integrer des controles de securite IaC et image
- Superviser la plateforme avec Prometheus et Grafana
- Fournir une base propre, documentee et exploitable sur GitHub

## Architecture

La stack deployee contient :

- `prometheus` pour la collecte des metriques
- `grafana` pour la visualisation
- `jenkins` pour la pipeline CI/CD
- `monitoring-app` comme application exemple conteneurisee
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

- Git, Python, pip, make et utilitaires systeme
- Docker Engine et active le service
- Terraform
- Ansible Core
- Checkov
- Trivy
- un miroir local du provider Terraform Docker pour contourner les acces limites a `registry.terraform.io`
- un fichier `terraform.rc` genere localement pour forcer Terraform a utiliser ce miroir

Note d'execution locale :

- pour garantir le deploiement sur cette machine Rocky Linux, les images runtime utilisees par defaut sont des images stables accessibles depuis Docker Hub
- l'objectif pedagogique reste identique, meme si l'implementation n'utilise plus Chainguard pour l'application et Prometheus dans cette variante locale

## Demarrage rapide

1. Initialiser le projet :

```bash
make bootstrap
```

2. Optionnel : personnaliser les variables Terraform :

```bash
cp infrastructure/terraform/terraform.tfvars.example infrastructure/terraform/terraform.tfvars
```

3. Valider la configuration :

```bash
make validate
```

4. Deployer la stack :

```bash
make deploy
```

5. Verifier Jenkins :

```bash
make setup-jenkins
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

## Commandes utiles

```bash
make security
make test
make destroy
```

Validation complete :

```bash
./scripts/validate-gitops.sh
```

Scan securite :

```bash
./scripts/security-scan.sh
```

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

## Publication sur GitHub

Une fois les outils installes :

```bash
git remote add origin <URL_DU_REPO_GITHUB>
git branch -M main
git add .
git commit -m "Initial commit: GitOps local pipeline"
./scripts/publish-github.sh
```

Le script `scripts/publish-github.sh` :

- verifie que `origin` existe
- avertit si l'arbre Git n'est pas propre
- teste l'authentification GitHub avant le push
- publie la branche courante avec `git push -u origin <branche>`

Si vous utilisez SSH, pensez a ajouter la cle publique de la machine a GitHub avant le premier push :

```bash
cat ~/.ssh/github_tp_devops_ed25519.pub
```

Le depot inclut deja :

- un `README.md` structure
- un workflow GitHub Actions de validation
- une organisation de projet exploitable
- une licence MIT

## Workflow GitHub Actions

Le fichier `.github/workflows/ci.yml` valide :

- le format Terraform
- la validation Terraform
- la syntaxe Ansible
- les scans Checkov
- les scripts shell

Cela permet d'avoir une verification automatique des pull requests et des pushes.

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
```

Rejouer la configuration :

```bash
ansible-playbook -i configuration/ansible/inventory.yml configuration/ansible/playbook.yml
```

## References utiles

- Docker Engine : https://docs.docker.com/engine/
- Terraform : https://developer.hashicorp.com/terraform
- Terraform CLI config et miroirs providers : https://developer.hashicorp.com/terraform/cli/config/config-file
- Ansible Core : https://docs.ansible.com/projects/ansible-core/
- Trivy : https://trivy.dev/
