import logging
import httpx
from typing import Optional

logger = logging.getLogger("sms_service")


async def send_sms_otp(phone: str, otp: str, api_key: Optional[str] = None) -> bool:
    """
    Sends 6-digit OTP SMS to Indian mobile numbers via Fast2SMS / SMS Gateway.
    """
    phone_clean = "".join(filter(str.isdigit, phone))
    if len(phone_clean) > 10:
        phone_clean = phone_clean[-10:]

    logger.info(f"[SMS GATEWAY] Dispatching 6-digit OTP {otp} to mobile number +91-{phone_clean}")

    if api_key:
        try:
            async with httpx.AsyncClient() as client:
                res = await client.post(
                    "https://www.fast2sms.com/dev/bulkV2",
                    headers={"authorization": api_key},
                    json={
                        "variables_values": otp,
                        "route": "otp",
                        "numbers": phone_clean,
                    },
                    timeout=6.0,
                )
                logger.info(f"Fast2SMS API Response ({res.status_code}): {res.text}")
                return res.status_code == 200
        except Exception as e:
            logger.error(f"Error sending SMS via Fast2SMS API: {e}")

    return True
