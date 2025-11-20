# --- 1단계: 종속성 설치 ---
FROM node:20-alpine AS builder

WORKDIR /app

# package.json & package-lock.json 복사
COPY package*.json ./

# 종속성 설치
RUN npm ci --omit=dev

# 앱 소스 코드 복사
COPY . .

# --- 2단계: 최종 이미지 ---
FROM node:20-alpine AS final

WORKDIR /frontend

# 빌더에서 node_modules 복사
COPY --from=builder /app/node_modules ./node_modules

# 앱 소스 및 public 폴더 복사
COPY --from=builder /app/app.js ./
COPY --from=builder /app/views ./views
COPY --from=builder /app/public ./public

# 포트 노출
EXPOSE 8000

# 컨테이너 시작
CMD ["node", "app.js"]
