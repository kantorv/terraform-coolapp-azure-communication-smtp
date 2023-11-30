import argparse
import smtplib

from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

import datetime

def main(smtp_username,smtp_password,smtp_host,smtp_port,from_address,to_address):

   body = """\
   Hi {recipient}, Your new SMTP server is READY!.

   
   username: {smtp_username}
   password: <sensitive>
   host:     {smtp_host}  
   port:     {smtp_port}
   starttls:      True
   
   Please DO NOT reply to this message!
   {now}
   """


   message = MIMEMultipart()
   message["From"] = from_address
   message["To"] = to_address
   message["Subject"] = "[Azure/Terraform] New SMTP server credentials"
   message["Bcc"] = to_address  # Recommended for mass emails

   # Add body to email
   message.attach(MIMEText(body, "plain"))
   message_body = message.as_string().format( 
      recipient=to_address, 
      sender=from_address, 
      now=datetime.datetime.now(),
      smtp_port=smtp_port, 
      smtp_username=smtp_username, 
      smtp_host=smtp_host
   )


   with smtplib.SMTP(smtp_host, smtp_port) as server:
      server.ehlo()
      server.starttls()
      server.login(smtp_username, smtp_password)
      server.sendmail(
         from_address,
         to_address,
         message_body
      )


if __name__ == "__main__":
   print("SEND_MAIL STARTED!!")
   parser = argparse.ArgumentParser(description = 'SMTP test email sending script')
   parser.add_argument("-s", "--smtp_host", help="Server / smart host", default="smtp.azurecomm.net" )
   parser.add_argument("-r", "--smtp_port", help="Port 587 (recommended) or port 25",choices=['25', '587'], default='587')
   parser.add_argument("-u", "--smtp_username", help="<Azure Communication Services Resource name>|<Entra Application ID>|<Entra Tenant ID>" )
   parser.add_argument("-p", "--smtp_password", help="Entra Application secret" )
   parser.add_argument("-f", "--from_address", help="Sender email" )
   parser.add_argument("-t", "--to_address", help="Recipient email" )
   args = parser.parse_args()


   main(
      smtp_username=args.smtp_username,
      smtp_password = args.smtp_password,
      from_address=args.from_address,
      smtp_host = args.smtp_host,
      smtp_port = args.smtp_port,
      to_address = args.to_address
   )