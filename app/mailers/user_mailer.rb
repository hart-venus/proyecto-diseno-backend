class UserMailer < ApplicationMailer
    default from: 'sistemalogisticotec@gmail.com'
  
    def send_notification_email
      mail(to: 'jcardonar@estudiantec.cr', subject: 'Notificación del Sistema Logístico TEC')
    end
  end