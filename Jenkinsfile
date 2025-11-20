pipeline {
    agent any

    environment {
        // --- 1. CONFIGURATION ---
        GCP_PROJECT_ID = 'cosmic-slate-469618-h1'
        GCP_ZONE = 'asia-south1-a'
        DOCKER_REGISTRY = "gcr.io/${GCP_PROJECT_ID}"
        
        // VM Names
        APP_VM = 'app-vm'
        
        // --- 2. CRITICAL DATABASE IP ---
        // This is the Internal IP of your Database VM
        DB_INTERNAL_IP = '10.160.0.6'

        // Docker Image Name
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
                    
                    // 1. Get the scanner tool
                    def scannerHome = tool 'SonarQubeScanner' 
                    
                    // 2. Use withCredentials to securely load the token into a variable
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_AUTH_TOKEN')]) {
                        
                        withSonarQubeEnv('sonar-server') {
                            sh """
                                ${scannerHome}/bin/sonar-scanner \
                                  -Dsonar.projectKey=book-manager \
                                  -Dsonar.sources=. \
                                  -Dsonar.host.url=http://localhost:9000 \
                                  -Dsonar.login=${SONAR_AUTH_TOKEN}
                            """
                        }
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
                echo 'Pushing Docker image to Google Artifact Registry...'
                sh """
                    gcloud auth configure-docker gcr.io --quiet
                    docker push ${APP_IMAGE}:${BUILD_NUMBER}
                    docker push ${APP_IMAGE}:latest
                """
            }
        }

        stage('Deploy to GCP VM') {
            steps {
                echo 'Deploying Application to App VM...'
                sh """
                    gcloud compute ssh ${APP_VM} --zone=${GCP_ZONE} --command="
                        sudo usermod -aG docker \$USER
                        gcloud auth configure-docker gcr.io --quiet
                        docker pull ${APP_IMAGE}:latest
                        docker stop book_app || true
                        docker rm book_app || true
                        
                        docker run -d --name book_app --restart always \
                          -p 5000:5000 \
                          -e MYSQL_HOST=${DB_INTERNAL_IP} \
                          -e MYSQL_USER=root \
                          -e MYSQL_PASSWORD=Nitish@1234 \
                          -e MYSQL_DATABASE=book_db \
                          -e SECRET_KEY=super-secret-key \
                          ${APP_IMAGE}:latest
                    "
                """
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}