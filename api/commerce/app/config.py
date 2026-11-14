"""Typed environment config (CueLABS standard: fail fast on missing settings).

Variable names follow system-design.md §10.3. Nothing else in the service
reads os.environ.
"""

from functools import lru_cache
from typing import Literal

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    port: int = 8083
    log_level: str = "INFO"

    kafka_brokers: str = Field(min_length=1)
    kafka_username: str = ""
    kafka_password: str = ""
    kafka_ssl_ca: str = ""
    kafka_group: str = "apparule-commerce"

    # K_SERVICE is set on Cloud Run, where CPU is allocated only while a
    # request runs (S-14): consumers then drain inside POST /internal/settle.
    k_service: str = ""
    # POST /internal/settle: a Google ID token for this audience (this
    # service's URL) from one of these comma-separated service accounts
    # (api/common's). Unset refuses every call.
    internal_audience: str = ""
    internal_invokers: str = ""

    storage_driver: Literal["gcs", "s3"] = "gcs"
    storage_bucket: str = Field(min_length=1)
    storage_prefix: str = Field(min_length=1, description="e.g. apparule/stg")
    storage_endpoint: str = ""
    storage_access_key: str = ""
    storage_secret_key: str = ""
    storage_use_ssl: bool = True

    # Money (S-6). Without a secret key commerce runs notify-only, the
    # self-host mode for deployments without Paystack (§10.2).
    paystack_secret_key: str = ""
    paystack_base_url: str = "https://api.paystack.co"
    # A-1: the platform fee, in basis points of the quote.
    platform_fee_bps: int = 1000

    # Push (FCM HTTP v1 via ADC; the project that owns the apps).
    google_cloud_project: str = ""
    # Money emails (Brevo, §6.5).
    brevo_api_key: str = ""
    brevo_from_email: str = ""
    brevo_from_name: str = "Apparule"
    # Social pushes coalesce over this window (§6.5).
    social_window_seconds: int = 300

    contract_dir: str = "contract"

    @property
    def kafka_broker_list(self) -> list[str]:
        return [b.strip() for b in self.kafka_brokers.split(",") if b.strip()]

    @property
    def on_cloud_run(self) -> bool:
        return bool(self.k_service)

    @property
    def internal_invoker_list(self) -> list[str]:
        return [i.strip() for i in self.internal_invokers.split(",") if i.strip()]

    @property
    def payments_enabled(self) -> bool:
        return bool(self.paystack_secret_key)


@lru_cache
def get_settings() -> Settings:
    return Settings()  # type: ignore[call-arg]  # values come from the environment
