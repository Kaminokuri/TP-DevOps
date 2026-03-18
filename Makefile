SHELL := /bin/bash
PROJECT_DIR := $(CURDIR)

.PHONY: bootstrap deploy configure validate test security destroy setup-jenkins

bootstrap:
	mkdir -p $(PROJECT_DIR)/jenkins_home
	mkdir -p $(PROJECT_DIR)/reports/security
	mkdir -p $(PROJECT_DIR)/monitoring/prometheus/rules
	mkdir -p $(PROJECT_DIR)/monitoring/grafana/provisioning/datasources
	mkdir -p $(PROJECT_DIR)/monitoring/grafana/provisioning/dashboards
	mkdir -p $(PROJECT_DIR)/monitoring/grafana/dashboards
	chmod +x $(PROJECT_DIR)/scripts/*.sh

deploy: bootstrap
	$(PROJECT_DIR)/scripts/deploy-local.sh

configure:
	ansible-galaxy collection install -r configuration/ansible/requirements.yml
	ansible-playbook -i configuration/ansible/inventory.yml configuration/ansible/playbook.yml

validate:
	$(PROJECT_DIR)/scripts/validate-gitops.sh

test:
	python3 tests/test_infrastructure.py

security:
	$(PROJECT_DIR)/scripts/security-scan.sh

destroy:
	terraform -chdir=infrastructure/terraform destroy -auto-approve

setup-jenkins:
	$(PROJECT_DIR)/scripts/setup-jenkins.sh

