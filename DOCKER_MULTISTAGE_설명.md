# Docker 멀티스테이지 빌드 설명

## 멀티스테이지 빌드란?

멀티스테이지 빌드(Multi-stage build)는 Docker 17.05 버전부터 지원되는 기능으로, 하나의 Dockerfile에서 여러 개의 `FROM` 문을 사용하여 빌드 과정을 여러 단계로 나누는 방식입니다.

## 왜 멀티스테이지 빌드가 필요한가?

### 1. **이미지 크기 최적화**

멀티스테이지 빌드의 가장 큰 장점은 최종 이미지 크기를 대폭 줄일 수 있다는 것입니다.

#### 예시: Client Dockerfile

```dockerfile
# 빌드 스테이지 - 개발 도구들이 모두 포함됨
FROM node:18-alpine as builder
WORKDIR /app
RUN apk add --no-cache git && \
    git clone https://github.com/excalidraw/excalidraw.git . && \
    yarn install && \
    yarn build:app:docker

# 프로덕션 스테이지 - 빌드된 결과물만 포함
FROM nginx:alpine
COPY --from=builder /app/excalidraw-app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
```

**이미지 크기 비교:**
- 싱글 스테이지 (node:18-alpine 기반): **약 400-500MB**
  - Node.js 런타임: ~120MB
  - node_modules: ~200-300MB
  - 빌드 도구 (git, yarn): ~50MB
  - 빌드된 파일: ~10-20MB

- 멀티스테이지 (nginx:alpine 기반): **약 30-40MB**
  - Nginx: ~20MB
  - 빌드된 정적 파일만: ~10-20MB

**결과: 약 90% 크기 감소!**

### 2. **보안 강화**

빌드 스테이지에 포함되는 개발 도구들은 프로덕션 환경에서 보안 취약점이 될 수 있습니다.

#### 제거되는 불필요한 요소들:
- **빌드 도구**: git, yarn, npm, compiler 등
- **개발 의존성**: devDependencies, 테스트 라이브러리 등
- **소스 코드**: 원본 소스 코드 (컴파일된 결과물만 필요)
- **빌드 캐시**: node_modules, .cache 디렉토리 등

이러한 도구들은 공격자가 악용할 수 있는 진입점이 될 수 있습니다.

### 3. **프로덕션 최적화**

프로덕션 환경에서는 빌드 도구가 필요 없고, 오직 실행에 필요한 파일만 있으면 됩니다.

#### Client 예시:
- **필요한 것**: 빌드된 HTML, CSS, JS 파일 + Nginx
- **불필요한 것**: Node.js, yarn, git, 소스 코드, node_modules

#### Socket Server 예시 (현재 미적용):
- **필요한 것**: 빌드된 JS 파일 + Node.js 런타임
- **불필요한 것**: yarn, git, 소스 코드, devDependencies

### 4. **배포 속도 향상**

이미지 크기가 작으면:
- **Docker pull 속도 증가**: 레지스트리에서 이미지를 더 빠르게 다운로드
- **Pod 시작 시간 단축**: Kubernetes에서 이미지를 더 빠르게 가져옴
- **네트워크 대역폭 절약**: 특히 여러 노드에 배포할 때 효과적

## 현재 레포지토리의 Dockerfile 분석

### 1. Client Dockerfile ✅ (멀티스테이지 적용됨)

```dockerfile
# 스테이지 1: 빌더
FROM node:18-alpine as builder
# ... 빌드 작업 ...

# 스테이지 2: 프로덕션
FROM nginx:alpine
COPY --from=builder /app/excalidraw-app/build /usr/share/nginx/html
```

**장점:**
- React 앱을 빌드한 후 정적 파일만 nginx로 서빙
- 최종 이미지에 Node.js나 빌드 도구가 포함되지 않음
- 매우 작고 빠른 이미지

### 2. Socket Dockerfile ❌ (싱글 스테이지)

```dockerfile
FROM node:18-alpine
WORKDIR /app
RUN apk add --no-cache git && \
    git clone https://github.com/excalidraw/excalidraw.git . && \
    cd excalidraw-room && \
    yarn install && \
    yarn build
WORKDIR /app/excalidraw-room
CMD ["yarn", "start"]
```

**문제점:**
- 빌드 도구(git, yarn)가 최종 이미지에 포함됨
- 소스 코드와 devDependencies가 모두 포함됨
- 불필요하게 큰 이미지

**개선 가능:**
멀티스테이지로 변경하여 빌드된 파일과 production dependencies만 포함

### 3. Server Dockerfile ✅ (빌드 불필요)

```dockerfile
FROM node:18-alpine
WORKDIR /app
RUN apk add --no-cache nginx
# ... nginx 설정만 ...
```

**설명:**
- 빌드 과정이 없는 단순 파일 서버
- 멀티스테이지가 필요 없음
- Nginx만 설치하여 파일을 서빙

## Socket Dockerfile 개선 제안

### 현재 (싱글 스테이지):

```dockerfile
FROM node:18-alpine
RUN apk add --no-cache git && \
    git clone https://github.com/excalidraw/excalidraw.git . && \
    cd excalidraw-room && \
    yarn install && \
    yarn build
CMD ["yarn", "start"]
```

**예상 크기**: ~300-400MB

### 개선안 (멀티스테이지):

```dockerfile
# 빌드 스테이지
FROM node:18-alpine as builder
WORKDIR /app
RUN apk add --no-cache git && \
    git clone https://github.com/excalidraw/excalidraw.git . && \
    cd excalidraw-room && \
    yarn install && \
    yarn build

# 프로덕션 스테이지
FROM node:18-alpine
WORKDIR /app/excalidraw-room

# 빌드된 파일과 production dependencies만 복사
COPY --from=builder /app/excalidraw-room/dist ./dist
COPY --from=builder /app/excalidraw-room/package.json ./package.json
COPY --from=builder /app/excalidraw-room/yarn.lock ./yarn.lock

# production dependencies만 설치
RUN yarn install --production --frozen-lockfile

EXPOSE 3002
CMD ["yarn", "start"]
```

**예상 크기**: ~150-200MB (약 50% 감소)

## 멀티스테이지 빌드 사용 시 주의사항

### 1. 빌드 시간
- 첫 빌드는 캐시가 없어 오래 걸릴 수 있음
- 하지만 Docker 레이어 캐싱을 잘 활용하면 이후 빌드는 빠름

### 2. 복사할 파일 파악
- 프로덕션에서 실행에 필요한 파일이 무엇인지 정확히 파악 필요
- 빠뜨린 파일이 있으면 런타임 에러 발생

### 3. 의존성 관리
- `yarn install --production`으로 devDependencies 제외
- package.json과 lock 파일 필수 복사

## 실전 팁

### 1. 빌드 스테이지에 이름 붙이기
```dockerfile
FROM node:18-alpine as builder  # 'builder'라는 이름 지정
FROM nginx:alpine
COPY --from=builder /app/build ./  # 이름으로 참조
```

### 2. 여러 빌드 스테이지 사용 가능
```dockerfile
FROM node:18-alpine as deps     # 의존성 설치
FROM node:18-alpine as builder  # 빌드
FROM node:18-alpine as runner   # 실행
```

### 3. 특정 스테이지까지만 빌드
```dockerfile
docker build --target builder -t myapp:build .
```

## 성능 비교

### Client (React 앱)

| 구성 | 이미지 크기 | 포함 내용 |
|------|------------|-----------|
| 싱글 스테이지<br/>(node:18-alpine) | ~400MB | Node.js + yarn + git + node_modules + 빌드 파일 |
| 멀티 스테이지<br/>(nginx:alpine) | ~30MB | Nginx + 빌드된 정적 파일만 |
| **감소율** | **92%** | - |

### Socket Server (WebSocket 서버)

| 구성 | 이미지 크기 | 포함 내용 |
|------|------------|-----------|
| 싱글 스테이지 (현재) | ~350MB | Node.js + yarn + git + 모든 dependencies + 소스 |
| 멀티 스테이지 (권장) | ~180MB | Node.js + 빌드 파일 + production deps만 |
| **감소율** | **48%** | - |

## 쿠버네티스 환경에서의 이점

### 1. 더 빠른 롤링 업데이트
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1
    maxSurge: 1
```
- 작은 이미지 = 더 빠른 pull = 더 빠른 업데이트

### 2. 노드 스토리지 절약
- 여러 노드에 이미지 캐싱 시 디스크 공간 절약
- 10개 노드 × 400MB 절약 = 4GB 절약

### 3. 더 빠른 스케일링
```bash
kubectl scale deployment excalidraw-client --replicas=10
```
- Pod가 새 노드에 스케줄될 때 이미지를 빠르게 pull

## 결론

멀티스테이지 빌드는:
- ✅ **이미지 크기를 대폭 감소** (50-90%)
- ✅ **보안을 강화** (불필요한 도구 제거)
- ✅ **배포 속도를 향상** (작은 이미지 = 빠른 전송)
- ✅ **프로덕션 최적화** (실행에 필요한 것만 포함)
- ✅ **비용 절감** (네트워크, 스토리지, 시간)

이 레포지토리에서는:
- **Client**: 멀티스테이지 적용됨 ✅
- **Socket**: 멀티스테이지 적용 권장 ⚠️
- **Server**: 빌드 불필요 (단순 파일 서버) ✅

## 참고 자료

- [Docker 공식 문서: Multi-stage builds](https://docs.docker.com/build/building/multi-stage/)
- [Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
