import base64
import json
import os
from google.cloud import logging
from google.cloud import pubsub_v1

# Initialize the Cloud Logging client
client = logging.Client()
logger = client.logger("high-cpu-alert-log")

def high_cpu_alert(event, context):
    """
    Cloud Function to handle high CPU usage alerts.
    Triggered by messages published to a Pub/Sub topic.
    """
    if 'data' in event:
        # Decode the Pub/Sub message
        pubsub_message = base64.b64decode(event['data']).decode('utf-8')
        alert = json.loads(pubsub_message)
        
        # Log the alert details
        logger.log_text(f"High CPU Alert received: {alert}")

        # Implement your alert response logic here
        instance_id = alert.get("incident", {}).get("resource_id")
        cpu_usage = alert.get("incident", {}).get("value")
        
        if cpu_usage:
            logger.log_text(f"Instance {instance_id} CPU usage is at {cpu_usage}", severity="CRITICAL")
            # Send an alert email (using a third-party service)
            send_alert_email(instance_id, cpu_usage)

def send_alert_email(instance_id, cpu_usage):
    """
    Send an alert email for high CPU usage incidents.
    """
    import smtplib
    from email.mime.text import MIMEText

    smtp_server = "smtp.example.com"
    smtp_port = 587
    smtp_user = "your-email@example.com"
    smtp_password = "your-email-password"

    msg = MIMEText(f"High CPU usage detected on instance {instance_id}: {cpu_usage}%")
    msg["Subject"] = "High CPU Usage Alert"
    msg["From"] = smtp_user
    msg["To"] = "alert-recipient@example.com"

    with smtplib.SMTP(smtp_server, smtp_port) as server:
        server.starttls()
        server.login(smtp_user, smtp_password)
        server.sendmail(smtp_user, ["alert-recipient@example.com"], msg.as_string())
