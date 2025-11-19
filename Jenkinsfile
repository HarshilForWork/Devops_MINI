pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'your-docker-registry'
        GCP_PROJECT_ID = 'your-gcp-project-id'
        GCP_ZONE = 'us-central1-a'
        
        // VM Details
        APP_VM = 'app-vm'
        DB_VM = 'database-vm'
        
        // Docker Image Names
        APP_IMAGE = "${DOCKER_REGISTRY}/book-manager-app"
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Pulling code from GitHub...'
                checkout scm
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                script {
                    echo 'Running SonarQube code quality scan...'
                    withSonarQubeEnv('SonarQube') {
                        sh '''
                            sonar-scanner \
                              -Dsonar.projectKey=book-manager \
                              -Dsonar.sources=. \
                              -Dsonar.host.url=http://localhost:9000 \
                              -Dsonar.python.coverage.reportPaths=coverage.xml
                        '''
                    }
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                script {
                    echo 'Checking SonarQube Quality Gate...'
                    timeout(time: 5, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo 'Building Application Docker image...'
                sh """
                    cd frontend
                    docker build -t ${APP_IMAGE}:${BUILD_NUMBER} .
                    docker tag ${APP_IMAGE}:${BUILD_NUMBER} ${APP_IMAGE}:latest
                """
            }
        }
        
        stage('Push to Registry') {
            steps {
                echo 'Pushing Docker image to registry...'
                sh """
                    docker push ${APP_IMAGE}:${BUILD_NUMBER}
                    docker push ${APP_IMAGE}:latest
                """
            }
        }
        
        stage('Deploy to GCP VM') {
            steps {
                echo 'Deploying Application to GCP VM...'
                sh """
                    gcloud compute ssh ${APP_VM} --zone=${GCP_ZONE} --command='
                        docker pull ${APP_IMAGE}:latest
                        docker stop book-app || true
                        docker rm book-app || true
                        docker run -d --name book-app -p 80:5000 \
                          -e MYSQL_HOST=<DB_VM_INTERNAL_IP> \
                          -e MYSQL_USER=root \
                          -e MYSQL_PASSWORD=Nitish@1234 \
                          -e MYSQL_DB=book_db \
                          ${APP_IMAGE}:latest
                    '
                """
            }
        }
        
        stage('Health Check') {
            steps {
                echo 'Running health checks...'
                sh """
                    curl -f http://${APP_VM}:80 || exit 1
                """
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline executed successfully!'
            // Send notification (email, Slack, etc.)
        }
        failure {
            echo 'Pipeline failed!'
            // Send failure notification
        }
        always {
            echo 'Cleaning up...'
            sh 'docker system prune -f'
        }
    }
}
