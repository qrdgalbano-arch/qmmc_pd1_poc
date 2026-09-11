from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.api.dependencies import require_staff
from app.database.session import get_db
from app.models import Exercise, Prescription, User, UserRole
from app.schemas.exercises import ExerciseCreate, ExerciseResponse
from app.schemas.prescriptions import PrescriptionCreate, PrescriptionResponse
from app.schemas.users import PatientSummary

router = APIRouter(
    prefix="/staff",
    tags=["staff"],
    dependencies=[Depends(require_staff)],
)


@router.get("/patients", response_model=list[PatientSummary])
def list_patients(db: Session = Depends(get_db)) -> list[User]:
    return list(
        db.scalars(
            select(User)
            .where(User.role == UserRole.patient)
            .order_by(User.full_name)
        )
    )


@router.post(
    "/exercises",
    response_model=ExerciseResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_exercise(
    payload: ExerciseCreate,
    db: Session = Depends(get_db),
) -> Exercise:
    existing = db.scalar(
        select(Exercise).where(Exercise.name == payload.name)
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Exercise name already exists",
        )

    exercise = Exercise(**payload.model_dump())
    db.add(exercise)
    db.commit()
    db.refresh(exercise)
    return exercise


@router.get("/exercises", response_model=list[ExerciseResponse])
def list_exercises(
    db: Session = Depends(get_db),
) -> list[Exercise]:
    return list(
        db.scalars(
            select(Exercise)
            .where(Exercise.is_active.is_(True))
            .order_by(Exercise.name)
        )
    )


@router.post(
    "/prescriptions",
    response_model=PrescriptionResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_prescription(
    payload: PrescriptionCreate,
    staff: User = Depends(require_staff),
    db: Session = Depends(get_db),
) -> Prescription:
    patient = db.get(User, payload.patient_id)

    if patient is None or patient.role != UserRole.patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient not found",
        )

    exercise = db.get(Exercise, payload.exercise_id)

    if exercise is None or not exercise.is_active:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Active exercise not found",
        )

    prescription = Prescription(
        **payload.model_dump(),
        staff_id=staff.id,
    )

    db.add(prescription)
    db.commit()

    created_prescription = db.scalar(
        select(Prescription)
        .options(joinedload(Prescription.exercise))
        .where(Prescription.id == prescription.id)
    )

    return created_prescription
