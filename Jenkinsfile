pipeline {
    agent any

    tools {
        git 'Default'      // Git tool in Jenkins Global Tool Configuration
        maven 'Maven3'     // Maven tool in Jenkins Global Tool Configuration
    }

    environment {
        APP_SERVER = '<app_public_ip>'   // Replace with Terraform output app_public_ip
        TOMCAT_USER = 'admin'            // Tomcat manager username
        TOMCAT_PASSWORD = 'password'     // Tomcat manager password
        WAR_FILE = 'target/java-webapp.war'
    }

    stages {
        stage('Checkout SCM') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/KMChandrashekhar/kmcdevops-java-webapp-devops.git',
                    credentialsId: 'jenkin-tomcat'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Deploy via Ansible') {
            steps {
                // Run the Ansible playbook from Jenkins
                ansiblePlaybook(
                    playbook: 'ansible/deploy-tomcat.yml',
                    inventory: "${APP_SERVER},",
                    extraVars: [
                        war_source: "${env.WAR_FILE}",
                        tomcat_user: "${TOMCAT_USER}",
                        tomcat_password: "${TOMCAT_PASSWORD}"
                    ]
                )
            }
        }
    }

    post {
        success {
            echo "Build and Deployment Successful!"
        }
        failure {
            echo "Build or Deployment Failed!"
        }
    }
}
