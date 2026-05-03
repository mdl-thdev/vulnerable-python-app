pipeline {
    agent any

    environment {
        SNYK_TOKEN = credentials('snyk-token')
        DOCKER_IMAGE = 'vulnerable-python-app'
        DOCKER_TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup Snyk') {
            steps {
                sh '''
                echo "Installing Snyk..."

                npm install -g snyk

                snyk version

                snyk auth $SNYK_TOKEN || true
                '''
            }
        }

        stage('Check Docker') {
            steps {
                sh '''
                echo "Checking Docker..."
                docker version
                which docker
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                docker build -t $DOCKER_IMAGE:$DOCKER_TAG .
                docker tag $DOCKER_IMAGE:$DOCKER_TAG $DOCKER_IMAGE:latest
                '''
            }
        }

        stage('Run Unit Tests') {
            steps {
                sh '''
                docker run --rm $DOCKER_IMAGE:$DOCKER_TAG python test_app.py
                '''
            }
        }

        stage('Snyk Dependency Scan') {
            steps {
                sh '''
                mkdir -p reports

                snyk test \
                    --file=requirements.txt \
                    --package-manager=pip \
                    --json > reports/deps.json || true
                '''
            }
        }

        stage('Snyk Container Scan') {
            steps {
                sh '''
                snyk container test \
                    $DOCKER_IMAGE:$DOCKER_TAG \
                    --json > reports/container.json || true
                '''
            }
        }

        stage('Snyk Code Scan') {
            steps {
                sh '''
                snyk code test \
                    --json > reports/code.json || true
                '''
            }
        }

        stage('Push to Snyk Dashboard') {
            steps {
                sh '''
                snyk monitor \
                    --file=requirements.txt \
                    --package-manager=pip \
                    --project-name="deps-$BUILD_NUMBER" \
                    || true

                snyk container monitor \
                    $DOCKER_IMAGE:$DOCKER_TAG \
                    --project-name="container-$BUILD_NUMBER" \
                    || true
                '''
            }
        }
    }

    post {
        always {
            sh '''
            docker rmi $DOCKER_IMAGE:$DOCKER_TAG || true
            '''
        }
    }
}