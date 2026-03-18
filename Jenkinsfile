pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  environment {
    APP_IMAGE = 'gitops-monitoring-app:ci'
    TF_IN_AUTOMATION = '1'
    PYTHONUNBUFFERED = '1'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        sh 'git log --oneline -5 || true'
      }
    }

    stage('Toolchain') {
      steps {
        sh '''
          set -eux
          docker --version
          terraform --version
          ansible-playbook --version
          checkov --version
          trivy --version
          python3 --version
        '''
      }
    }

    stage('Security Scan - IaC') {
      parallel {
        stage('Checkov Terraform') {
          steps {
            sh '''
              set -eux
              mkdir -p reports/security
              checkov -d infrastructure/terraform \
                --framework terraform \
                --output junitxml \
                --output-file-path reports/security \
                || true
            '''
          }
          post {
            always {
              junit allowEmptyResults: true, testResults: 'reports/security/results_junitxml.xml'
            }
          }
        }

        stage('Checkov Ansible') {
          steps {
            sh '''
              set -eux
              mkdir -p reports/security/ansible
              checkov -d configuration/ansible \
                --framework ansible \
                --output junitxml \
                --output-file-path reports/security/ansible \
                || true
            '''
          }
          post {
            always {
              junit allowEmptyResults: true, testResults: 'reports/security/ansible/results_junitxml.xml'
            }
          }
        }
      }
    }

    stage('Build Application Container') {
      steps {
        sh '''
          set -eux
          docker build -t "${APP_IMAGE}" application/docker
        '''
      }
    }

    stage('Security Scan - Container') {
      steps {
        sh '''
          set -eux
          mkdir -p reports/security
          trivy image \
            --severity HIGH,CRITICAL \
            --exit-code 0 \
            --format table \
            "${APP_IMAGE}" | tee reports/security/trivy-app.txt
        '''
      }
    }

    stage('Deploy Infrastructure') {
      steps {
        sh '''
          set -eux
          terraform -chdir=infrastructure/terraform init
          terraform -chdir=infrastructure/terraform fmt -check
          terraform -chdir=infrastructure/terraform validate
          terraform -chdir=infrastructure/terraform plan -out=tfplan
          terraform -chdir=infrastructure/terraform apply -auto-approve tfplan
        '''
      }
    }

    stage('Configure Services') {
      steps {
        sh '''
          set -eux
          ansible-galaxy collection install -r configuration/ansible/requirements.yml
          ansible-playbook -i configuration/ansible/inventory.yml configuration/ansible/playbook.yml
        '''
      }
    }

    stage('Health Check') {
      steps {
        sh '''
          set -eux
          sleep 15
          curl -fsS http://localhost:9090/-/healthy
          curl -fsS http://localhost:3000/api/health
          curl -fsS http://localhost:8080/login > /dev/null
          curl -fsS http://localhost:3001/health
        '''
      }
    }

    stage('Integration Tests') {
      steps {
        sh '''
          set -eux
          python3 tests/test_infrastructure.py
        '''
      }
    }
  }

  post {
    always {
      archiveArtifacts allowEmptyArchive: true, artifacts: 'reports/**/*'
    }
    success {
      echo 'Pipeline GitOps executee avec succes.'
    }
    failure {
      echo 'La pipeline GitOps a echoue. Consulter les logs Jenkins.'
    }
  }
}

