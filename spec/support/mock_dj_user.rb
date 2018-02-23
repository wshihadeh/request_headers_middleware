# frozen_string_literal: true
class User
  def persisted?
    true
  end

  def send_email
    'email sent'
  end
end
