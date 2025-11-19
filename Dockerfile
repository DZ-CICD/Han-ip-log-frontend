# --- 1단계: 빌드 및 종속성 설치 (Builder Stage) ---
# 이 단계는 종속성을 설치하고 코드를 컴파일하는 역할만 수행합니다.
FROM node:20-alpine AS builder

WORKDIR /app

# 1. package.json 및 잠금 파일 복사 (캐시 활용을 위해 먼저 복사)
COPY package.json package-lock.json ./

# 2. 종속성 설치 (개발 관련 모듈 제외)
# 이전에 발생했던 'MODULE_NOT_FOUND' 에러를 여기서 방지합니다.
RUN npm ci --omit=dev

# 3. 나머지 소스 코드 복사
COPY . .

# 4. (SPA인 경우) 빌드 명령어 실행:
# 만약 React/Vue/Angular 등 SPA 프레임워크를 사용한다면 아래 주석을 해제하세요.
# RUN npm run build 

# --- 2단계: 최종 실행 단계 (Production/Runtime Stage) ---
# 최종 사용자 환경은 최소한의 파일만 포함합니다.
FROM node:20-alpine AS final

# 컨테이너 내부 작업 경로 설정
WORKDIR /frontend

# 1. 이전 빌드 단계에서 설치된 node_modules와 소스 코드를 최종 이미지로 복사
# 빌드 도구를 제외하고 실행에 필요한 파일만 가져와 이미지 크기를 최소화합니다.
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/app.js .
COPY --from=builder /app/. .
# 만약 빌드 결과물(e.g., dist)이 있다면 그것만 복사합니다.

# 애플리케이션 포트 명시
EXPOSE 8000

# 3. 컨테이너 시작 명령어 (프로덕션에 적합하도록 디버그 플래그 제거)
# 이전 CrashLoopBackOff 오류를 해결하는 핵심 단계입니다.
CMD ["node", "app.js"]