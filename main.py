import os
import smtplib
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
    engine = sqlalchemy.create_engine(db_url)

    logging.debug("SqlAlchemy engine created")
    record = None
    with engine.connect() as connection:
        query = sqlalchemy.text("SELECT * FROM public.participant WHERE id = 23")
        result = connection.execute(query)
        record = result.fetchone()
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
