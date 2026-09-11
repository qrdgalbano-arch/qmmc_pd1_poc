from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings

app = FastAPI(
    title="QMMC PD1 Proof of Concept API",
    version="0.1.0",
    description=(
        "Backend proof of concept for an offline-first rehabilitation "
        "application without pose estimation or deep learning."
    ),
)

origins = [
    origin.strip()
    for origin in settings.cors_origins.split(",")
    if origin.strip()
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root():
    return {
        "message": "QMMC PD1 Proof of Concept API is running.",
    }


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "qmmc-pd1-backend",
        "proof_of_concept": True,
        "pose_estimation": "not included",
        "deep_learning": "not included",
    }
