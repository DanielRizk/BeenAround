from fastapi import APIRouter

router = APIRouter()

@router.get("/health")
def health():
    # Simple health endpoint for monitoring / load balancers
    return {"status": "ok"}
