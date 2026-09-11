from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    database_url: str = (
        "postgresql+psycopg://qmmc_user:change_this_password@db:5432/qmmc_pd1"
    )
    cors_origins: str = (
        "http://localhost,http://localhost:8080,http://10.0.2.2:8000"
    )

    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=False,
        extra="ignore",
    )


settings = Settings()
