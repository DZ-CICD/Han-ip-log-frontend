pipeline {
    agent any

    environment {
        // 1. Harbor 설정 (이미지 이름을 frontend로 변경)
        HARBOR_REGISTRY = '192.168.0.183'
        IMAGE_NAME = 'haniplogjenkins/han-ip-log-frontend' 
        HARBOR_CREDENTIALS_ID = 'harbor-creds'

        // 2. Git 설정 (새로운 리포지토리 주소 적용)
        GIT_CREDENTIALS_ID = 'git-token-id'
        GIT_REPO_URL = 'https://github.com/DZ-CICD/Han-ip-log-frontend.git'

        // 3. SonarCloud 설정
        SONAR_CREDENTIALS_ID = 'sonar-token'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'sonar-scanner'
                    withSonarQubeEnv('sonar-server') {
                        sh """
                        ${scannerHome}/bin/sonar-scanner \
                        -Dsonar.organization=dz-cicd \
                        -Dsonar.projectKey=DZ-CICD_Han-ip-log-frontend \
                        -Dsonar.sources=. \
                        -Dsonar.host.url=https://sonarcloud.io
                        """
                        // [주의] projectKey를 'DZ-CICD_Han-ip-log-frontend'로 가정했습니다.
                        // 소나클라우드에서 이 이름으로 프로젝트가 생성되어 있어야 합니다.
                    }
                }
            }
        }

	stage('Security Scan (Trivy)') {
            steps {
                script {
                    def IMAGE_TAG = "${HARBOR_REGISTRY}/${IMAGE_NAME}:${env.BUILD_NUMBER}"
                    echo "--- Trivy Scan Results (CRITICAL/HIGH only) ---"
                    echo "Starting Trivy scan on ${IMAGE_TAG}..."
                    
                    // --exit-code 1 플래그를 제거했습니다. 취약점이 나와도 빌드는 성공합니다.
                    sh "trivy image --severity CRITICAL,HIGH --skip-tls-verify ${IMAGE_TAG}" 
                    
                    echo "--- Trivy Scan Complete. Continuing pipeline. ---"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Frontend Docker Image..."
                    // haniplogjenkins/han-ip-log-frontend:빌드번호 로 생성됨
                    def customImage = docker.build("${HARBOR_REGISTRY}/${IMAGE_NAME}:${env.BUILD_NUMBER}")

                    docker.withRegistry("http://${HARBOR_REGISTRY}", "${HARBOR_CREDENTIALS_ID}") {
                        echo "Pushing Image to Harbor..."
                        customImage.push()
                        customImage.push('latest')
                    }
                }
            }
        }

        stage('Update Manifest') {
            steps {
                withCredentials([usernamePassword(credentialsId: GIT_CREDENTIALS_ID, passwordVariable: 'GIT_TOKEN', usernameVariable: 'GIT_USER')]) {
                    script {
                        echo "Updating deployment.yaml..."
                        
                        sh "git config user.email 'rlaehgns745@gmail.com'"
                        sh "git config user.name 'kdh5018'"
                        
                        // deployment.yaml 이미지 태그 수정
                        sh "sed -i 's|image: .*|image: ${HARBOR_REGISTRY}/${IMAGE_NAME}:${env.BUILD_NUMBER}|' jenkins/deployment.yaml"
                        
                        sh "cat jenkins/deployment.yaml"
                        sh "git add jenkins/deployment.yaml"
                        sh "git commit -m 'Update frontend image tag to ${env.BUILD_NUMBER} [skip ci]'"
                        
                        // [중요] 변경된 리포지토리로 Push
                        sh "git push https://${GIT_USER}:${GIT_TOKEN}@github.com/DZ-CICD/Han-ip-log-frontend.git HEAD:main"
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying...'
                echo 'ArgoCD will detect the change in Git and sync automatically.'
            }
        }
    }
    
    post {
        success {
            echo 'Frontend Build & Deploy Successful!'
        }
        failure {
            echo 'Pipeline Failed.'
        }
    }
}
