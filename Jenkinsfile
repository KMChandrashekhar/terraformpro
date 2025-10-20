pipeline {
  agent any

  environment {
    APP_USER = 'ubuntu'
    APP_IP = '<<replace_with_app_public_ip>>'  // replace after terraform output
    SSH_KEY_ID = 'app-key'   // Jenkins credential ID (add your private key in Jenkins)
  }

  stages {
    stage('Checkout') {
      steps {
        git 'https://github.com/KMChandrashekhar/kmcdevops-java-webapp-devops.git'
      }
    }

    stage('Build Maven Package') {
      steps {
        sh 'mvn clean package -DskipTests'
      }
    }

    stage('Install Tomcat (Ansible)') {
      steps {
        writeFile file: 'ansible/inventory.ini', text: "[app]\n${APP_IP} ansible_user=${APP_USER}\n"
        sh 'ansible-playbook -i ansible/inventory.ini ansible/tomcat.yml --private-key ~/.ssh/id_rsa'
      }
    }

    stage('Deploy WAR to Tomcat') {
      steps {
        sshagent (credentials: [env.SSH_KEY_ID]) {
          sh '''
            WAR=$(ls target/*.war | head -n1)
            scp -o StrictHostKeyChecking=no $WAR ${APP_USER}@${APP_IP}:/opt/tomcat/apache-tomcat-10.1.33/webapps/
            ssh -o StrictHostKeyChecking=no ${APP_USER}@${APP_IP} "sudo pkill -f tomcat || true; nohup /opt/tomcat/apache-tomcat-10.1.33/bin/startup.sh &"
          '''
        }
      }
    }
  }
}
