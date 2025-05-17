#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import argparse
import subprocess
import logging
from pathlib import Path

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("notify")

def send_notification(message, subject=None, recipients=None, priority="normal", channels=None):
    """
    Envia notificação por múltiplos canais
    
    Args:
        message: Texto da mensagem
        subject: Assunto (para e-mail)
        recipients: Lista de destinatários (para e-mail)
        priority: Prioridade ("high", "normal", "low")
        channels: Lista de canais a usar ("email", "sms", "telegram")
    
    Returns:
        bool: True se pelo menos um canal foi bem-sucedido
    """
    
    if not channels:
        channels = ["email"]  # E-mail como padrão
    
    if not recipients:
        recipients = [os.environ.get("DEFAULT_EMAIL", "adiel.rios@abp.org.br")]
    
    if not subject:
        subject = "Notificação AssistPericias"
        if priority == "high":
            subject = "URGENTE: " + subject
    
    # Diretório atual
    current_dir = Path(__file__).parent
    
    success = False
    
    # Enviar por e-mail
    if "email" in channels:
        for recipient in recipients:
            try:
                email_script = current_dir / "email_notify.py"
                subprocess.run(
                    [sys.executable, str(email_script), recipient, subject, message],
                    check=True
                )
                success = True
            except subprocess.CalledProcessError as e:
                logger.error(f"Erro ao enviar e-mail para {recipient}: {e}")
    
    return success

def main():
    """Função principal"""
    parser = argparse.ArgumentParser(description="Sistema unificado de notificações")
    parser.add_argument("message", help="Texto da mensagem")
    parser.add_argument("--subject", help="Assunto para e-mail")
    parser.add_argument("--recipients", nargs="+", help="Lista de destinatários")
    parser.add_argument(
        "--priority",
        choices=["high", "normal", "low"],
        default="normal",
        help="Prioridade da notificação"
    )
    parser.add_argument(
        "--channels",
        nargs="+",
        choices=["email", "sms", "telegram"],
        help="Canais a serem utilizados"
    )
    
    args = parser.parse_args()
    
    success = send_notification(
        args.message,
        args.subject,
        args.recipients,
        args.priority,
        args.channels
    )
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
