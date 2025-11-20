# --- 1단계: 빌드 및 종속성 설치 (Builder Stage) ---
FROM node:20-alpine AS builder

WORKDIR /app

# 1. package.json 및 잠금 파일 복사 (캐시 활용)
COPY package.json package-lock.json ./

# 2. 종속성 설치 (개발 의존성 제외)
RUN npm ci --omit=dev

# 3. 전체 소스 코드 복사
COPY . .

# (SPA 빌드가 필요한 경우 여기에 빌드 명령어 추가)
# RUN npm run build


# --- 2단계: 최종 실행 단계 (Production/Runtime Stage) ---
FROM node:20-alpine AS final

WORKDIR /frontend

# 1. 빌드된 node_modules와 앱 소스 복사
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/app.js . 

# 2. 정적 파일 및 템플릿 폴더 명시적 복사
COPY --from=builder /app/public ./public
COPY --from=builder /app/views ./views
COPY --from=builder /app/utils ./utils

# 3. 앱 포트
EXPOSE 8000

# 4. 실행 명령
CMD ["node", "app.js"]
