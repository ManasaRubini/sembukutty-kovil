import asyncio
import logging
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Optional
import httpx
from app.config import settings

logger = logging.getLogger("email_service")


def _html_body(member_name: str, otp: str) -> str:
    return f"""
    <html>
      <body style="font-family: Arial, sans-serif; color: #333; line-height: 1.6; background:#f5f5f5;">
        <div style="max-width:480px;margin:30px auto;background:#fff;padding:30px;border-radius:12px;border:1px solid #e0e0e0;">
          <h2 style="color:#721c24;text-align:center;margin-bottom:4px;">Sembukutty Sastha Kovil</h2>
          <p style="text-align:center;color:#888;font-size:13px;margin-top:0;">Billing &amp; Accounts System</p>
          <hr style="border:none;border-top:1px solid #f0e0e0;margin:16px 0;">
          <p>Hello <strong>{member_name or 'User'}</strong>,</p>
          <p>Your registration verification code is:</p>
          <div style="background:#fdf3f3;border:2px dashed #721c24;padding:18px;text-align:center;border-radius:10px;margin:20px 0;">
            <span style="font-size:34px;font-weight:bold;letter-spacing:10px;color:#721c24;">{otp}</span>
          </div>
          <p style="font-size:13px;color:#6c757d;">⏱ This code expires in <strong>5 minutes</strong>.</p>
          <p style="font-size:12px;color:#999;">If you did not request this, you can safely ignore this email.</p>
          <hr style="border:none;border-top:1px solid #f0e0e0;margin:16px 0;">
          <p style="font-size:11px;color:#bbb;text-align:center;">Sembukutty Sastha Kovil — Billing &amp; Accounts</p>
        </div>
      </body>
    </html>
    """


def _text_body(member_name: str, otp: str) -> str:
    return f"""Hello {member_name or 'User'},

Your Sembukutty Sastha Kovil registration verification code is:

  {otp}

This code expires in 5 minutes.
If you did not request this, you can safely ignore this email.

— Sembukutty Sastha Kovil Billing & Accounts
"""


async def _send_via_brevo(to_email: str, member_name: str, otp: str) -> bool:
    """Send OTP email via Brevo API (Free 300 emails/day to ANY recipient without domain restriction)."""
    api_key = getattr(settings, "BREVO_API_KEY", "").strip()
    if not api_key:
        return False

    sender_email = (
        getattr(settings, "BREVO_SENDER_EMAIL", "").strip()
        or getattr(settings, "SMTP_FROM_EMAIL", "").strip()
        or "sembukuttysastha.kovil@gmail.com"
    )

    payload = {
        "sender": {"name": "Sembukutty Sastha Kovil", "email": sender_email},
        "to": [{"email": to_email, "name": member_name or "Devotee"}],
        "subject": f"🔑 {otp} — Your Sembukutty Sastha Kovil Verification Code",
        "htmlContent": _html_body(member_name, otp),
        "textContent": _text_body(member_name, otp),
    }

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            r = await client.post(
                "https://api.brevo.com/v3/smtp/email",
                headers={"api-key": api_key, "Content-Type": "application/json"},
                json=payload,
            )
        if r.status_code in (200, 201, 202):
            logger.info(f"[BREVO SUCCESS] OTP email delivered to {to_email}")
            return True
        else:
            logger.error(f"[BREVO ERROR] Status {r.status_code}: {r.text}")
            # If Brevo returned sender validation error, retry with manasarubini06@gmail.com
            if r.status_code == 400 and "sender" in r.text.lower() and sender_email != "manasarubini06@gmail.com":
                logger.info("[BREVO RETRY] Retrying Brevo API with default sender manasarubini06@gmail.com...")
                payload["sender"]["email"] = "manasarubini06@gmail.com"
                async with httpx.AsyncClient(timeout=15.0) as retry_client:
                    r_retry = await retry_client.post(
                        "https://api.brevo.com/v3/smtp/email",
                        headers={"api-key": api_key, "Content-Type": "application/json"},
                        json=payload,
                    )
                if r_retry.status_code in (200, 201, 202):
                    logger.info(f"[BREVO RETRY SUCCESS] OTP email delivered to {to_email}")
                    return True
                else:
                    logger.error(f"[BREVO RETRY ERROR] Status {r_retry.status_code}: {r_retry.text}")
            return False
    except Exception as e:
        logger.error(f"[BREVO EXCEPTION] {e}")
        return False


async def _send_via_resend(to_email: str, member_name: str, otp: str) -> bool:
    """Send OTP email via Resend.com REST API."""
    api_key = getattr(settings, "RESEND_API_KEY", "").strip()
    resend_from = getattr(settings, "RESEND_FROM_EMAIL", "").strip() or "onboarding@resend.dev"

    if not api_key:
        return False

    payload = {
        "from": f"Sembukutty Sastha Kovil <{resend_from}>",
        "to": [to_email],
        "subject": f"🔑 {otp} — Your Sembukutty Sastha Kovil Verification Code",
        "html": _html_body(member_name, otp),
        "text": _text_body(member_name, otp),
    }

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            r = await client.post(
                "https://api.resend.com/emails",
                headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
                json=payload,
            )
        if r.status_code in (200, 201):
            logger.info(f"[RESEND SUCCESS] OTP email delivered to {to_email}")
            return True
        else:
            logger.error(f"[RESEND ERROR] Status {r.status_code}: {r.text}")
            return False
    except Exception as e:
        logger.error(f"[RESEND EXCEPTION] {e}")
        return False


def _send_via_smtp_sync(to_email: str, member_name: str, otp: str) -> bool:
    """Fallback: send via Gmail SMTP (synchronous, runs on background thread)."""
    smtp_host = getattr(settings, "SMTP_HOST", "smtp.gmail.com") or "smtp.gmail.com"
    smtp_port = int(getattr(settings, "SMTP_PORT", 587) or 587)
    smtp_user = getattr(settings, "SMTP_USER", "").strip()
    smtp_pass = getattr(settings, "SMTP_PASSWORD", "").strip()
    from_email = getattr(settings, "SMTP_FROM_EMAIL", "").strip() or smtp_user

    if not smtp_user or not smtp_pass:
        logger.warning("[SMTP] SMTP_USER or SMTP_PASSWORD not configured.")
        return False

    msg = MIMEMultipart("alternative")
    msg["Subject"] = f"🔑 {otp} — Your Sembukutty Sastha Kovil Verification Code"
    msg["From"] = f"Sembukutty Sastha Kovil <{from_email}>"
    msg["To"] = to_email
    msg.attach(MIMEText(_text_body(member_name, otp), "plain"))
    msg.attach(MIMEText(_html_body(member_name, otp), "html"))

    try:
        if smtp_port == 465:
            with smtplib.SMTP_SSL(smtp_host, smtp_port, timeout=12.0) as server:
                server.login(smtp_user, smtp_pass)
                server.sendmail(from_email, [to_email], msg.as_string())
        else:
            with smtplib.SMTP(smtp_host, smtp_port, timeout=12.0) as server:
                server.ehlo()
                server.starttls()
                server.ehlo()
                server.login(smtp_user, smtp_pass)
                server.sendmail(from_email, [to_email], msg.as_string())
        logger.info(f"[SMTP SUCCESS] OTP email sent to {to_email}")
        return True
    except Exception as e:
        logger.error(f"[SMTP ERROR] {e}")
        return False


async def send_otp_email(to_email: str, member_name: str, otp: str) -> bool:
    """
    Send OTP email.
    1. Tries Brevo API first (300 free emails/day to ANY recipient in the world).
    2. Tries Resend API next.
    3. Tries Gmail SMTP fallback.
    """
    to_email = to_email.strip()
    if not to_email:
        return False

    # 1. Try Brevo API first if configured
    brevo_key = getattr(settings, "BREVO_API_KEY", "").strip()
    if brevo_key:
        success = await _send_via_brevo(to_email, member_name, otp)
        if success:
            return True

    # 2. Try Resend API if configured
    resend_key = getattr(settings, "RESEND_API_KEY", "").strip()
    if resend_key:
        success = await _send_via_resend(to_email, member_name, otp)
        if success:
            return True

    # 3. Fallback to Gmail SMTP on background thread
    return await asyncio.to_thread(_send_via_smtp_sync, to_email, member_name, otp)
