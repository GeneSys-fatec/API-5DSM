package com.backend.tecsys.auth.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

/**
 * Serviço de envio de e-mails transacionais.
 * Requer spring.mail.* configurado em application.properties.
 * Quando o JavaMailSender não estiver configurado, o envio é apenas logado
 * (facilita testes locais sem SMTP real).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username:noreply@tecsys.com.br}")
    private String from;

    /**
     * Envia o e-mail de recuperação de senha com o link de redefinição.
     *
     * @param destinatario  endereço de e-mail do usuário
     * @param nomeUsuario   nome de exibição do usuário
     * @param resetLink     URL completa incluindo o token
     * @param expiracaoMin  tempo de expiração em minutos (para exibição no texto)
     */
    public void sendPasswordResetEmail(String destinatario, String nomeUsuario,
                                       String resetLink, int expiracaoMin) {
        try {
            SimpleMailMessage msg = new SimpleMailMessage();
            msg.setFrom(from);
            msg.setTo(destinatario);
            msg.setSubject("[Tecsys] Redefinição de senha");
            msg.setText(buildText(nomeUsuario, resetLink, expiracaoMin));
            mailSender.send(msg);
            log.info("E-mail de recuperação de senha enviado para {}", destinatario);
        } catch (Exception e) {
            // Em ambiente de desenvolvimento sem SMTP configurado, apenas loga.
            log.warn("Falha ao enviar e-mail de recuperação para {} — link gerado: {} | erro: {}",
                    destinatario, resetLink, e.getMessage());
        }
    }

    private String buildText(String nome, String link, int expiracaoMin) {
        return """
                Olá, %s!

                Recebemos uma solicitação para redefinir a senha da sua conta no Tecsys.

                Clique no link abaixo para criar uma nova senha:
                %s

                Este link expira em %d minuto(s).

                Caso não tenha solicitado a redefinição, ignore este e-mail — sua senha permanece inalterada.

                Equipe Tecsys
                """.formatted(nome, link, expiracaoMin);
    }
}

