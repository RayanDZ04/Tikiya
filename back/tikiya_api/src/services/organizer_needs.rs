use lettre::message::Mailbox;
use lettre::transport::smtp::authentication::Credentials;
use lettre::{AsyncSmtpTransport, AsyncTransport, Message, Tokio1Executor};

use crate::dto::OrganizerNeedsRequest;
use crate::error::ApiError;
use crate::state::AppState;

pub async fn send_organizer_needs_email(
    state: &AppState,
    payload: &OrganizerNeedsRequest,
) -> Result<(), ApiError> {
    if state.config.smtp_host.trim().is_empty()
        || state.config.smtp_username.trim().is_empty()
        || state.config.smtp_password.trim().is_empty()
    {
        tracing::error!("organizer_needs.smtp_not_configured");
        return Err(ApiError::ServiceUnavailable);
    }

    let from: Mailbox = state
        .config
        .smtp_from
        .parse()
        .map_err(|_| ApiError::Validation("SMTP_FROM invalide".into()))?;
    let to: Mailbox = state
        .config
        .organizer_needs_to_email
        .parse()
        .map_err(|_| ApiError::Validation("ORGANIZER_NEEDS_TO_EMAIL invalide".into()))?;

    let subject = format!(
        "[Tikiya Pro] Nouveau formulaire organisateur - {} {}",
        payload.first_name, payload.last_name
    );

    let text_body = format!(
        "Nouveau formulaire organisateur\n\nPrénom: {}\nNom: {}\nEmail: {}\nTéléphone: {}\nSite/Instagram: {}\n",
        payload.first_name, payload.last_name, payload.email, payload.phone, payload.instagram
    );

    let html_body = format!(
        "<h2>Nouveau formulaire organisateur</h2><ul><li><strong>Prénom:</strong> {}</li><li><strong>Nom:</strong> {}</li><li><strong>Email:</strong> {}</li><li><strong>Téléphone:</strong> {}</li><li><strong>Site/Instagram:</strong> {}</li></ul>",
        payload.first_name,
        payload.last_name,
        payload.email,
        payload.phone,
        payload.instagram
    );

    let email = Message::builder()
        .from(from)
        .to(to)
        .subject(subject)
        .header(lettre::message::header::ContentType::TEXT_HTML)
        .body(html_body)
        .map_err(|_| ApiError::Internal)?;

    let creds = Credentials::new(
        state.config.smtp_username.clone(),
        state.config.smtp_password.clone(),
    );

    let mailer = AsyncSmtpTransport::<Tokio1Executor>::relay(&state.config.smtp_host)
        .map_err(|_| ApiError::Internal)?
        .port(state.config.smtp_port)
        .credentials(creds)
        .build();

    mailer.send(email).await.map_err(|e| {
        tracing::error!(error = ?e, text_body = %text_body, "organizer_needs.email_send_failed");
        ApiError::ServiceUnavailable
    })?;

    Ok(())
}
