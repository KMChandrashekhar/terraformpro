pipeline {
    agent any

    environment {
        APP_USER = 'ubuntu'   // EC2 Ubuntu user
        SSH_KEY_PATH = '/home/jenkins/.ssh/jenkin-tomcat.pem'  // path to your PEM
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/KMChandrashekhar/kmcdevops-java-webapp-devops.git'
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('infra') {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Get App IP from Terraform') {
            steps {
                dir('infra') {
                    script {
                        APP_IP = sh(script: "terraform output -raw app_public_ip", returnStdout: true).trim()
                        echo "App server IP: ${APP_IP}"
                    }
                }
            }
        }

        stage('Build Maven Package') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Generate Ansible Inventory') {
            steps {
                script {
                    writeFile file: 'ansible/inventory.ini', text: """[app]
${APP_IP} ansible_user=${APP_USER} ansible_ssh_private_key_file=${SSH_KEY_PATH}
"""
                }
            }
        }

        stage('Install Tomcat (Ansible)') {
            steps {
                sh 'ansible-playbook -i ansible/inventory.ini ansible/tomcat.yml'
            }
        }

        stage('Deploy WAR to Tomcat') {
            steps {
                sh '''
                WAR=$(ls target/*.war | head -n1)
                scp -o StrictHostKeyChecking=no -i ${SSH_KEY_PATH} $WAR ${APP_USER}@${APP_IP}:/opt/tomcat/apache-tomcat-10.1.33/webapps/
                ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_PATH} ${APP_USER}@${APP_IP} "sudo pkill -f tomcat || true; nohup /opt/tomcat/apache-tomcat-10.1.33/bin/startup.sh &"
                '''
            }
        }
    }

    post {
        failure {
            echo "Pipeline failed. Check the logs for details."
        }
    }
}
