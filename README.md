# Omni-Persona AI Architecture

<div align="center">
<h3>"상황에 맞는 페르소나, 그리고 환각 없는 완벽한 실시간 답변"</h3>
<p>Flutter, FastAPI, Redis, 그리고 로컬 LLM(Ollama)을 결합하여 구축한 <b>하이브리드 RAG 기반 멀티 페르소나 AI 어시스턴트</b>입니다.</p>
</div>

>[깃허브]
>https://github.com/lshee9008/omni-persona-ai-architecture-test


## 1. 프로젝트 배경 및 문제 정의

기존의 상용 범용 AI(ChatGPT, Claude 등) 기반 챗봇 서비스들은 실무 도입 시 다음과 같은 치명적인 한계를 가집니다.

1. **할루시네이션(환각)**: 최신 트렌드나 로컬 신조어에 대해 학습되지 않은 경우, 그럴싸한 거짓말을 생성함.
2. **데이터 프라이버시 및 비용**: 민감한 사내 데이터를 외부 API로 전송해야 하는 보안 리스크와 토큰당 과금 부담.
3. **획일화된 응답 톤앤매너**: 챗봇의 성격이 고정되어 있어, 사용자/상황별 맞춤형 UX(페르소나) 제공이 어려움.

이 프로젝트는 위 문제들을 근본적으로 해결하기 위해 **로컬 GPU 추론(Ollama) + 하이브리드 RAG(내부 DB + 실시간 웹 검색) + 동적 페르소나 시스템**으로 설계된 풀스택 파이프라인입니다.

---

## 2. 시스템 아키텍처
![](https://velog.velcdn.com/images/fpalzntm/post/50293568-4e5a-4744-bd9a-978a5c61a630/image.png)


### 핵심 설계 원칙

* **Mac GPU 네이티브 가속**: 컨테이너 내부에서 LLM을 돌릴 때 발생하는 오버헤드를 제거하기 위해, 백엔드(FastAPI)는 Docker에 올리고 AI 추론(Ollama)은 호스트 Mac의 Metal API를 직접 사용하도록 분리 설계.
* **하이브리드 RAG**: 내부 도메인 지식(FAISS)과 실시간 웹 정보(Tavily)를 동시에 검색하여 프롬프트에 주입하는 엔터프라이즈급 검색 증강 생성.
* **이중 메모리 구조**: Redis를 통해 세션별 대화 맥락을 초고속으로 캐싱(TTL 관리)하고, 영구 보관용 RDBMS로 비동기 로깅.

---

## 3. 트러블슈팅: "두쫀쿠" 할루시네이션 정복기

최신 SNS 유행어인 **'두쫀쿠(두바이 쫀득 쿠키)'**를 시스템이 어떻게 이해하고 정확한 답변을 도출해 내는지에 대한 아키텍처 고도화 여정입니다. 이 과정에서 발생한 세 번의 실패와 최종 해결 과정을 기록했습니다.

### Phase 1: 순수 LLM의 환각 (Hallucination)

초기 로컬 모델(gemma3:4b)에게 "두쫀쿠가 뭐야?"라고 질문했습니다. AI는 과거 학습 데이터에 해당 신조어가 없었음에도 "부산 지역 특유의 두부+쫀디기 간식"이라는 매우 구체적인 거짓말을 지어냈습니다.

> **문제 원인**: LLM 특유의 사실 왜곡 및 최신 정보 부재.
![](https://velog.velcdn.com/images/fpalzntm/post/d6824651-1f4e-4c5c-bcc8-973fd77afef3/image.png)
><p><i>▲ 1차 실패: 부산 특유의 간식거리라는 전형적인 환각 현상</i></p>
</div>

### Phase 2: 검색 엔진 도입과 OOV (Out of Vocabulary) 사태

실시간 웹 검색을 위해 무료 검색 엔진인 `DuckDuckGo` API를 연동했습니다. 하지만 예상치 못한 시스템 크래시와 기괴한 답변이 돌아왔습니다.

1. **LangChain 파싱 버그**: 구버전 래퍼(Wrapper)의 `timedelta.__format__` 처리 버그로 인해 런타임 에러 발생. -> *최신 라이브러리로 강제 업데이트하여 해결.*
2. **의미론적 오인(Semantic Misunderstanding)**: 검색 엔진이 한국어 신조어인 "두쫀쿠"를 발음이 비슷한 영어 단어인 **"Toucan(투칸 - 앵무새)"**으로 오인하여 앵무새의 깃털 색깔을 브리핑하는 참사 발생.

> **문제 원인**: 해외 기반 일반 검색 엔진의 한국어/신조어 파악 능력 한계 및 단순 키워드 매칭의 오류.
![](https://velog.velcdn.com/images/fpalzntm/post/7ae6be77-f9f3-4189-be21-93a3b2e2270e/image.png)
><p><i>▲ 2차 실패: 두쫀쿠를 앵무새로 오인하여 검색해온 처참한 결과</i></p>
</div>

### Phase 3: 아키텍처 전면 개편 (Hybrid RAG + Q&A Pairing)

기존의 한계를 돌파하기 위해 아키텍처와 데이터 주입 방식을 전면 수정했습니다.

1. **AI 전용 검색 엔진(Tavily) 도입**: DuckDuckGo를 폐기하고, LLM에게 요약된 정보를 먹여주기 위해 만들어진 AI 전용 검색 엔진 `Tavily Search`로 모듈 교체.
2. **Q&A 페어 주입 기법**: 임베딩 모델이 모르는 단어(OOV)를 단순 기호로 치환해버리는 문제를 해결하기 위해, 내부 Vector DB(FAISS)에 데이터를 넣을 때 단순 평문이 아닌 `질문: 두쫀쿠가 뭐야? 답변: 두바이 쫀득 쿠키입니다.` 형식의 **Q&A 페어**로 강제 주입하여 매칭률 100% 달성.
3. **환경변수 은닉**: `TAVILY_API_KEY`를 코드에서 분리하여 `.env`와 `docker-compose.yml`을 통해 런타임에 안전하게 주입.
![](https://velog.velcdn.com/images/fpalzntm/post/4bff0e04-bbd5-45d4-a96b-467fc9aa5599/image.png)
<p><i>▲ 최종 성공: 하이브리드 RAG가 재료, 유행 이유(장원영), 현재 시세(5000~1만원)까지 완벽 브리핑</i></p>
</div>

**최종 결과**: AI는 더 이상 앵무새나 부산 간식을 찾지 않고, 내부 DB 지식과 최신 웹 크롤링 정보를 융합하여 상용 서비스(Perplexity 등) 수준의 완벽한 답변을 생성해 냈습니다.

---

## 4. 기술 스택

| 영역 | 기술 | 설명 |
| --- | --- | --- |
| **Frontend** | Flutter, Markdown | 모던 챗 UI (말풍선, 아바타, 마크다운 렌더링, 오토 스크롤) |
| **Backend** | Python, FastAPI, SQLAlchemy | 비동기 기반 RESTful API 및 SSE(Server-Sent Events) 스트리밍 처리 |
| **AI/LLM** | Ollama (gemma3:4b), LangChain | 데이터 프라이버시가 보장되는 로컬 LLM 구동 (Mac Metal 가속) |
| **RAG/Search** | FAISS, HuggingFace, Tavily API | 내부 지식 검색 엔진 및 실시간 AI 최적화 웹 검색 하이브리드 결합 |
| **Database** | Redis, SQLite | 세션 기반 히스토리 초고속 캐싱 및 영구 데이터베이스 |
| **Infra** | Docker, Docker Compose | 백엔드 생태계(API, Redis) 컨테이너화 및 `.env` 환경변수 격리 |

---

## 5. 주요 기능

* **실시간 스트리밍 답변 (SSE)**: 대기 시간 없이 AI의 사고 과정을 한 글자씩 실시간으로 화면에 렌더링.
* **멀티 페르소나 스위칭**: 사용자가 드롭다운 메뉴로 '친절한 어시스턴트', '시니컬한 튜터' 등 페르소나를 변경하면, 시스템 프롬프트가 즉각 반영되어 톤앤매너 변경.
* **하이브리드 지식 검색**: 사전 학습되지 않은 질문은 내부 DB(FAISS)와 외부 웹(Tavily)을 동시 병렬 검색하여 프롬프트에 자동 주입.
* **실시간 지식 주입 파이프라인**: Swagger UI(`POST /knowledge`)를 통해 관리자가 실시간으로 AI를 교육(Vector DB 업데이트) 가능.

---

## 6. 디렉토리 구조

```text
omni-persona-ai-architecture-test/
├── front/
│   └── flutter_omni_persona_ai_architecture_test/
│       ├── lib/
│       │   ├── models/            # 메시지 데이터 모델
│       │   ├── screens/           # UI 화면 (chat_screen.dart 등)
│       │   └── services/          # HTTP 통신 및 SSE 스트림 수신 로직
│       └── pubspec.yaml
├── back/
│   ├── app/
│   │   ├── main.py                # FastAPI 엔트리포인트 & App Lifespan 관리
│   │   ├── rag.py                 # FAISS + Tavily 하이브리드 RAG 코어 로직
│   │   ├── database.py            # SQLAlchemy 연결 및 세션 관리
│   │   ├── models.py              # 데이터베이스 테이블 스키마
│   │   ├── schemas.py             # Pydantic 데이터 검증
│   │   └── routers/
│   │       └── chat.py            # 채팅 라우터 (RAG 컨텍스트 주입 & SSE 스트리밍)
│   ├── requirements.txt
│   └── Dockerfile                 # Python 3.11 Slim 기반 컨테이너 설정
├── docker-compose.yml             # API, Redis 오케스트레이션 및 포트/볼륨 매핑
├── .env                           # API 키 및 환경 변수 (Git 추적 제외)
└── README.md

```

---

## 7. 실행 가이드 (Quick Start)

### 사전 요구사항

* Node.js / Flutter SDK
* Docker & Docker Compose
* Mac OS (Ollama GPU 가속 권장 환경)
* [Tavily AI](https://tavily.com/) API Key

### 1. 환경 변수 설정

프로젝트 최상위 디렉토리에 `.env` 파일을 생성하고 API 키를 입력합니다.

```bash
echo "TAVILY_API_KEY=tvly-당신의_타빌리_API_키를_입력하세요" > .env

```

### 2. 인프라 및 백엔드 실행 (Docker)

로컬 DB 캐시를 초기화하고 백엔드 서버를 백그라운드에서 실행합니다.

```bash
docker-compose down -v
docker-compose --env-file .env up -d --build

```

### 3. 로컬 LLM 서버 실행 (Mac Host)

[Ollama 공식 홈페이지](https://ollama.com/)에서 설치 후 새로운 터미널을 열어 모델을 로드합니다.

```bash
ollama run gemma3:4b

```

### 4. 프론트엔드 (Flutter) 실행

```bash
cd front/flutter_omni_persona_ai_architecture_test
flutter pub get
flutter run

```

### 5. (옵션) 실시간 지식 주입 테스트

웹 브라우저에서 `http://localhost:8000/docs` 접속 후 `POST /knowledge` 엔드포인트를 통해 Q&A 데이터를 실시간으로 학습시킬 수 있습니다.

---

## 8. 회고 및 향후 개선 방향

* **배운 점**: 단순한 라이브러리 조합을 넘어, 데이터가 파이프라인을 통과하며 어떻게 변형되는지(OOV 문제, 토크나이징 한계)를 깊이 이해하게 되었습니다. Docker 환경에서의 네트워크 매핑과 환경변수 생명 주기에 대한 실무적인 트러블슈팅 경험을 쌓았습니다.
* **개선 방향**: 현재의 SQLite 로깅을 PostgreSQL + pgvector로 마이그레이션하여, 대규모 트래픽에서의 사용자별 장기 기억(Long-term Memory) RAG 시스템으로 고도화할 계획입니다.
