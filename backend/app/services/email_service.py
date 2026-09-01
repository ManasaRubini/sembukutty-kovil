import logging
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Optional
from app.config import settings

logger = logging.getLogger("email_service")


async def send_otp_email(to_email: str, member_name: str, otp: str) -> bool:
    """
    Dispatches a 6-digit Registration OTP email via SMTP to member's email address.
    """
    to_email_clean = to_email.strip()
    if not to_email_clean:
        return False

    smtp_host = getattr(settings, "SMTP_HOST", "smtp.gmail.com") or "smtp.gmail.com"
    smtp_port = int(getattr(settings, "SMTP_PORT", 587) or 587)
    smtp_user = getattr(settings, "SMTP_USER", "").strip()
    smtp_pass = getattr(settings, "SMTP_PASSWORD", "").strip()
    from_email = getattr(settings, "SMTP_FROM_EMAIL", "").strip() or smtp_user or "noreply@sembukuttykovil.com"

    logger.info(f"[SMTP EMAIL SERVICE] Preparing OTP email for {to_email_clean} using server {smtp_host}:{smtp_port}")

    if not smtp_user or not smtp_pass or "yourtempleemail" in smtp_user:
        logger.warning(
            "[SMTP CONFIG WARNING] SMTP_USER or SMTP_PASSWORD is not configured in backend/.env. "
            "OTP will be logged to server logs. Fill in backend/.env to send real emails to inbox."
        )
        logger.info(f"[SMTP DEMO LOG] Member: {member_name or 'User'} | Email: {to_email_clean} | OTP: {otp}")
        return True

    text_body = f"""Hello {member_name or 'User'},

Your verification code is:

{otp}

This code will expire in 5 minutes.

If you did not request this code, you can safely ignore this email.
"""

    html_content = f"""
    <html>
      <body style="font-family: Arial, sans-serif; color: #333; line-height: 1.6;">
        <div style="max-width: 500px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
          <h2 style="color: #721c24; text-align: center;">Sembukutty Sastha Kovil</h2>
          <h3 style="color: #495057; text-align: center;">Your Verification Code</h3>
          <p>Hello <strong>{member_name or 'User'}</strong>,</p>
          <p>Your verification code is:</p>
          <div style="background-color: #f8f9fa; border: 1px dashed #721c24; padding: 15px; text-align: center; border-radius: 8px; margin: 20px 0;">
            <span style="font-size: 28px; font-weight: bold; letter-spacing: 5px; color: #721c24;">{otp}</span>
          </div>
          <p style="font-size: 13px; color: #6c757d;">This code will expire in 5 minutes.</p>
          <p style="font-size: 12px; color: #999;">If you did not request this code, you can safely ignore this email.</p>
        </div>
      </body>
    </html>
    """

    msg = MIMEMultipart("alternative")
    msg["Subject"] = "Your Verification Code"
    msg["From"] = from_email
    msg["To"] = to_email_clean
    msg.attach(MIMEText(text_body, "plain"))
    msg.attach(MIMEText(html_content, "html"))

    try:
        if smtp_port == 465:
            with smtplib.SMTP_SSL(smtp_host, smtp_port, timeout=10.0) as server:
                server.login(smtp_user, smtp_pass)
                server.sendmail(from_email, [to_email_clean], msg.as_string())
        else:
            with smtplib.SMTP(smtp_host, smtp_port, timeout=10.0) as server:
                server.ehlo()
                server.starttls()
                server.ehlo()
                server.login(smtp_user, smtp_pass)
                server.sendmail(from_email, [to_email_clean], msg.as_string())

        logger.info(f"[SMTP EMAIL SUCCESS] Successfully delivered OTP email to {to_email_clean} via {smtp_host}")
        return True
    except smtplib.SMTPAuthenticationError as e:
        logger.error(
            f"[SMTP AUTH ERROR] Invalid email or App Password for {smtp_user}: {e}. "
            "If using Gmail, make sure to use a 16-character App Password (not your normal Gmail password)."
        )
    except Exception as e:
        logger.error(f"[SMTP ERROR] Failed to send email to {to_email_clean} via {smtp_host}:{smtp_port}: {e}")

    return False
