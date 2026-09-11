from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.auth import router as auth_router
from app.api.patients import router as patients_router
from app.api.staff import router as staff_router

app = FastAPI(
    title="QMMC PD1 Proof of Concept",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost",
        "http://127.0.0.1",
    ],
    allow_origin_regex=r"^http://(localhost|127\.0\.0\.1):\d+$",
    allow_credentials=False,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)

app.include_router(auth_router)
app.include_router(staff_router)
app.include_router(patients_router)


@app.get("/")
def root() -> dict:
    return {"message": "QMMC PD1 Proof of Concept API"}


@app.get("/health")
def health() -> dict:
    return {
        "status": "healthy",
        "service": "qmmc-pd1-backend",
        "proof_of_concept": True,
        "pose_estimation": "not included",
        "deep_learning": "not included",
    }

