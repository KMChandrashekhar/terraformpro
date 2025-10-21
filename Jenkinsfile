pipeline {
    agent any

    tools {
        git 'Default'      // Git tool name in Global Tool Configuration
        maven 'Maven3'     // Maven tool name in Global Tool Configuration
    }

    environment {
        TOMCAT_URL = 'http://localhost:8080/manager/text'
        TOMCAT_USER = 'admin'       // Replace with your Tomcat manager username
        TOMCAT_PASSWORD = 'password' // Replace with your Tomcat manager password
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

        stage('Deploy to Tomcat') {
            steps {
                script {
                    // Path to generated WAR file
                    def warFile = 'target/kmcdevops-java-webapp-devops.war'
                    
                    // Deploy using Tomcat manager
                    sh """
                        curl -u $TOMCAT_USER:$TOMCAT_PASSWORD \
                        -T $warFile \
                        "$TOMCAT_URL/deploy?path=/myapp&update=true"
                    """
                }
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

