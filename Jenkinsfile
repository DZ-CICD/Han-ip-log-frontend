pipeline {
    agent any

    environment {
        // 1. Harbor 설정 (이미지 이름은 변경 요청에 따라 'haniplogjenkins/han-ip-log-frontend'로 유지)
        HARBOR_REGISTRY = '192.168.0.183'
        IMAGE_NAME = 'haniplogjenkins/han-ip-log-frontend'
        HARBOR_CREDENTIALS_ID = 'harbor-creds'

        // 2. Git 설정
        GIT_CREDENTIALS_ID = 'git-token-id'
        GIT_REPO_URL = 'https://github.com/DZ-CICD/Han-ip-log-frontend.git'

        // 3. SonarCloud 설정
        SONAR_CREDENTIALS_ID = 'sonar-token'
    }

    stages {
        // 1. 소스 코드 가져오기
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // 2. SonarCloud 코드 품질 검사
        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'sonar-scanner'

                    // 소나큐브 검사 실행 (품질 통제)
                    withSonarQubeEnv('sonar-server') {
                        sh """
                        ${scannerHome}/bin/sonar-scanner \
                        -Dsonar.organization=dz-cicd \
                        -Dsonar.projectKey=DZ-CICD_Han-ip-log-frontend \
                        -Dsonar.sources=. \
                        -Dsonar.host.url=https://sonarcloud.io
                        """
                    }
                    // 참고: 품질 게이트(Quality Gate) 실패 시 빌드를 멈추려면
                    // withSonarQubeEnv 블록 뒤에 waitForQualityGate()를 추가해야 합니다.
                }
            }
        }

        // 3. 이미지 빌드 및 보안 검사 (통합된 단계)
        stage('Build & Security Scan') {
            steps {
                script {
                    echo "Building Frontend Docker Image..."
                    // A. 이미지 빌드 (로컬에 생성)
                    def customImage = docker.build("${HARBOR_REGISTRY}/${IMAGE_NAME}:${env.BUILD_NUMBER}")
                    def IMAGE_TAG = "${HARBOR_REGISTRY}/${IMAGE_NAME}:${env.BUILD_NUMBER}"
                    
                    // B. Trivy 보안 검사 (Build 직후, Fail Fast 적용)
                    echo "--- Trivy Scan Started (CRITICAL/HIGH only) ---"
                    // --exit-code 1 옵션을 넣으면 HIGH/CRITICAL 발견 시 여기서 파이프라인 실패
                    sh "trivy image --severity CRITICAL,HIGH --insecure ${IMAGE_TAG}" 
                    echo "--- Trivy Scan Complete. ---"
                    
                    // C. Harbor Push (검사 통과 후 푸시)
                    docker.withRegistry("http://${HARBOR_REGISTRY}", "${HARBOR_CREDENTIALS_ID}") {
                        echo "Pushing Image to Harbor..."
                        customImage.push()
                        customImage.push('latest')
                    }
                }
            }
        }

        // 4. Kubernetes 배포 파일(Manifest) 버전 업데이트
        stage('Update Manifest') {
            steps {
                withCredentials([usernamePassword(credentialsId: GIT_CREDENTIALS_ID, passwordVariable: 'GIT_TOKEN', usernameVariable: 'GIT_USER')]) {
                    script {
                        echo "Updating deployment.yaml..."

                        sh "git config user.email 'rlaehgns745@gmail.com'"
                        sh "git config user.name 'kdh5018'"

                        // deployment.yaml 파일의 이미지 태그 수정
                        sh "sed -i 's|image: .*|image: ${HARBOR_REGISTRY}/${IMAGE_NAME}:${env.BUILD_NUMBER}|' jenkins/deployment.yaml"

                        sh "cat jenkins/deployment.yaml"

                        // Git Push (무한 루프 방지를 위해 [skip ci] 포함)
                        sh "git add jenkins/deployment.yaml"
                        sh "git commit -m 'Update frontend image tag to ${env.BUILD_NUMBER} [skip ci]'"
                        sh "git push https://${GIT_USER}:${GIT_TOKEN}@github.com/DZ-CICD/Han-ip-log-frontend.git HEAD:main"
                    }
                }
            }
        }

        // 5. 배포 알림
        stage('Deploy') {
            steps {
                echo 'Deploying...'
                echo 'ArgoCD will detect the change in Git and sync automatically.'
            }
        }
    }

    post {
        success {
            echo 'Frontend Build, Analysis, Push, and Manifest Update Successful!'
        }
        failure {
            echo 'Pipeline Failed.'
        }
    }
}
