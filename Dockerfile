# --- 1단계: 종속성 설치 ---
FROM node:20-alpine AS builder

WORKDIR /app

# package.json & package-lock.json 복사
COPY package*.json ./

# 👇 추가: npm 캐시를 완전히 비워 빌드 캐시 오염을 막습니다.
RUN npm cache clean --force

# 👇 수정: npm ci 대신 npm install을 사용합니다.
RUN npm install --omit=dev

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
