pipeline {
    agent any

    environment {
        APP_USER = 'ubuntu'
        SSH_KEY_ID = 'app-key' // Jenkins credential ID for your private key
    }

    stages {
        stage('Checkout') {
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

        stage('Get App Server IP') {
            steps {
                dir('infra') {
                    script {
                        env.APP_IP = sh(
                            script: "terraform output -raw app_public_ip",
                            returnStdout: true
                        ).trim()
                        echo "App server IP: ${env.APP_IP}"
                    }
                }
            }
        }

        stage('Build Maven Package') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Install Tomcat (Ansible)') {
            steps {
                writeFile file: 'ansible/inventory.ini', text: "[app]\n${env.APP_IP} ansible_user=${env.APP_USER}\n"
                sh 'ansible-playbook -i ansible/inventory.ini ansible/tomcat.yml --private-key ~/.ssh/id_rsa'
            }
        }

        stage('Deploy WAR to Tomcat') {
            steps {
                sshagent (credentials: [env.SSH_KEY_ID]) {
                    sh """
                        WAR=\$(ls target/*.war | head -n1)
                        scp -o StrictHostKeyChecking=no \$WAR ${env.APP_USER}@${env.APP_IP}:/opt/tomcat/apache-tomcat-10.1.33/webapps/
                        ssh -o StrictHostKeyChecking=no ${env.APP_USER}@${env.APP_IP} \\
                            "sudo pkill -f tomcat || true; nohup /opt/tomcat/apache-tomcat-10.1.33/bin/startup.sh &"
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Deployment completed successfully! App running at http://${env.APP_IP}:8080"
        }
        failure {
            echo "Pipeline failed. Check console output for errors."
        }
    }
}
