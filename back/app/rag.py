import os
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_community.tools.tavily_search import TavilySearchResults

# ---------------------------------------------------------
# 1. 내부 지식 데이터베이스 (FAISS Vector DB) 로직
# ---------------------------------------------------------
embeddings = HuggingFaceEmbeddings(model_name="jhgan/ko-sroberta-multitask")
DB_PATH = "/app/faiss_index"
vector_store = None


def init_rag():
    global vector_store
    if os.path.exists(DB_PATH):
        # 기존에 학습시킨 지식이 있다면 불러오기
        vector_store = FAISS.load_local(DB_PATH, embeddings, allow_dangerous_deserialization=True)
        print("✅ 기존 Vector DB(FAISS) 로드 완료")
    else:
        # 없다면 빈 DB 생성
        vector_store = FAISS.from_texts(["이것은 초기화용 데이터입니다."], embeddings)
        vector_store.save_local(DB_PATH)
        print("✅ 새 Vector DB(FAISS) 생성 완료")


def add_document(text: str):
    """새로운 지식을 Vector DB에 주입합니다."""
    global vector_store
    vector_store.add_texts([text])
    vector_store.save_local(DB_PATH)


def search_documents(query: str, k=2):
    """사용자 질문과 가장 유사한 내부 지식 k개를 찾아서 반환합니다."""
    global vector_store
    if not vector_store:
        return []
    results = vector_store.similarity_search(query, k=k)
    return [doc.page_content for doc in results]


# ---------------------------------------------------------
# 2. 실시간 웹 검색 (Tavily AI Search) 로직
# ---------------------------------------------------------
def search_web(query: str) -> str:
    """Tavily AI 검색 API를 이용해 인터넷에서 최신 정보를 정확하게 검색합니다."""
    try:
        import os
        from langchain_community.tools.tavily_search import TavilySearchResults

        # 💡 1. 환경변수에서 키를 직접 가져옵니다.
        api_key = os.getenv("TAVILY_API_KEY")

        if not api_key:
            print("🚨 에러: TAVILY_API_KEY가 없습니다. .env를 확인하세요.")
            return "검색 엔진 API 키가 설정되지 않았습니다."

        # 💡 2. 객체를 생성할 때 api_key를 명시적으로 집어넣습니다.
        search_tool = TavilySearchResults(max_results=3, tavily_api_key=api_key)

        results = search_tool.invoke(query)

        if not results:
            return "검색 결과가 없습니다."

        search_context = "\n".join([f"- {res['content']}" for res in results])
        print(f"🌐 Tavily 웹 검색 완료: {query}")
        return search_context

    except Exception as e:
        print(f"웹 검색 오류: {e}")
        return "검색 결과를 가져오지 못했습니다."