import os
import smtplib
import requests
import sqlalchemy
import logging
from email.message import EmailMessage

def check_and_send_email(request):
    db_user = os.environ.get("DB_USER")
    db_password = os.environ.get("DB_PASSWORD")
    db_name = os.environ.get("DB_NAME")
    db_host = os.environ.get("DB_HOST")

    request_json = request.get_json()

    db_url = f"postgresql://{db_user}:{db_password}@{db_host}/{db_name}"

    url = "https://voting-backend-11-6prvk2lemq-uc.a.run.app:443/api/participants/25"
    response = requests.get(url)

    record = None

    if response.status_code == 200 and response.content.strip() != b'null':
        record = {"id": 23}
    else:
        logging.warning("ID not found in the response.")

    engine = sqlalchemy.create_engine(db_url)

    logging.debug("SqlAlchemy engine created")
    message = "Hello, this is a test message."
    msg = EmailMessage()
    subject = 'Notification about survey'
    msg['Subject'] = subject
    msg['From'] = 'emailforsabreproject132@gmail.com'
    msg.set_content("I want to remind you that You have some survey to do. :)")
    msg['To'] = "przemoaaa@gmail.com"



    gmail_user = "emailforsabreproject132@gmail.com"
    gmail_app_password = "ibnhmrqxzuwwkvls"

    try:
        with smtplib.SMTP('smtp.gmail.com', 587) as server:
            server.ehlo()
            server.starttls()
            server.ehlo()
            server.login(gmail_user, gmail_app_password)
            server.send_message(msg)

        logging.debug('Email sent!')
    except Exception as exception:
        logging.error("Error: %s!\n\n" % exception)

    engine.dispose()

    logging.debug("Success!")
    return str(record)
