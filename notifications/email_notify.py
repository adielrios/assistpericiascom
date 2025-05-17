#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import smtplib
import os
import sys
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("email_notify")

def send_email(recipient, subject, message, html=False):
    """Envia e-mail de notificação"""
    
    # Obter configurações do e-mail
    smtp_server = os.environ.get("SMTP_SERVER", "smtp.gmail.com")
    smtp_port = int(os.environ.get("SMTP_PORT", 587))
    smtp_user = os.environ.get("SMTP_USER", "adiel.rios@abp.org.br")
    smtp_password = os.environ.get("SMTP_PASSWORD", "")
    
    if not smtp_password:
        logger.warning("Senha SMTP não configurada. Simulando envio de e-mail.")
        logger.info(f"Para: {recipient}")
        logger.info(f"Assunto: {subject}")
        logger.info(f"Mensagem: {message}")
        return True
    
    # Criar mensagem
    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = smtp_user
    msg["To"] = recipient
    
    # Adicionar corpo da mensagem
    if html:
        msg.attach(MIMEText(message, "html"))
    else:
        msg.attach(MIMEText(message, "plain"))
    
    try:
        # Conectar ao servidor SMTP
        server = smtplib.SMTP(smtp_server, smtp_port)
        server.ehlo()
        server.starttls()
        server.ehlo()
        
        # Login no servidor
        server.login(smtp_user, smtp_password)
        
        # Enviar e-mail
        server.sendmail(smtp_user, recipient, msg.as_string())
        server.quit()
        
        logger.info(f"E-mail enviado para {recipient}")
        return True
    except Exception as e:
        logger.error(f"Erro ao enviar e-mail: {e}")
        return False

def main():
    """Função principal"""
    import argparse
    
    # Configurar parser de argumentos
    parser = argparse.ArgumentParser(description="Enviar notificação por e-mail")
    parser.add_argument("recipient", help="Destinatário do e-mail")
    parser.add_argument("subject", help="Assunto do e-mail")
    parser.add_argument("message", help="Mensagem do e-mail")
    parser.add_argument("--html", action="store_true", help="Enviar como HTML")
    
    # Processar argumentos
    args = parser.parse_args()
    
    # Enviar e-mail
    success = send_email(args.recipient, args.subject, args.message, args.html)
    
    # Retornar status
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
