pipeline {
    agent any

    environment {
        SNYK_TOKEN = credentials('snyk-token')
        DOCKER_IMAGE = 'vulnerable-python-app'
        DOCKER_TAG = "$BUILD_NUMBER"
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
                echo "Installing Snyk via npm..."

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
                docker version || true
                which docker || true
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                echo "Building Docker image..."
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

        stage('Snyk Security Scan - Dependencies') {
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

        stage('Snyk Security Scan - Docker Image') {
            steps {
                sh '''
                snyk container test \
                    $DOCKER_IMAGE:$DOCKER_TAG \
                    --json > reports/container.json || true
                '''
            }
        }

        stage('Snyk Code Analysis') {
            steps {
                sh '''
                snyk code test \
                    --json > reports/code.json || true
                '''
            }
        }

        stage('Generate Security Report') {
            steps {
                sh '''
                echo "Security Summary" > reports/summary.txt
                date >> reports/summary.txt
                echo "Image: $DOCKER_IMAGE:$DOCKER_TAG" >> reports/summary.txt
                cat reports/summary.txt
                '''
            }
        }

        stage('Archive Reports') {
            steps {
                archiveArtifacts artifacts: 'reports/**/*', allowEmptyArchive: true
            }
        }

        stage('Snyk Monitor - Push to Dashboard') {
            steps {
                sh '''
                echo "Pushing to Snyk..."

                snyk monitor \
                    --file=requirements.txt \
                    --package-manager=pip \
                    --project-name="vulnerable-python-app-deps-$BUILD_NUMBER" \
                    --remote-repo-url="https://github.com/mdl-thdev/vulnerable-python-app" \
                    || true

                snyk container monitor \
                    $DOCKER_IMAGE:$DOCKER_TAG \
                    --project-name="vulnerable-python-app-container-$BUILD_NUMBER" \
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

        success {
            echo 'Pipeline completed successfully!'
        }

        unstable {
            echo 'Pipeline completed with warnings'
        }

        failure {
            echo 'Pipeline failed'
        }
    }
}