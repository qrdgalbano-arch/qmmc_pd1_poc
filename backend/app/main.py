from fastapi import FastAPI

from app.api.auth import router as auth_router

app = FastAPI(
    title="QMMC PD1 Proof of Concept",
    version="0.1.0",
)

app.include_router(auth_router)


@app.get("/")
def root() -> dict:
    return {
        "message": "QMMC PD1 Proof of Concept API",
    }


@app.get("/health")
def health() -> dict:
    return {
        "status": "healthy",
        "service": "qmmc-pd1-backend",
        "proof_of_concept": True,
        "pose_estimation": "not included",
        "deep_learning": "not included",
    }
