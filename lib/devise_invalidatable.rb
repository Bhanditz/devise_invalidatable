unless defined?(Devise)
  require 'devise'
end
require 'devise_invalidatable'

Devise.add_module(:invalidatable,
                  model: 'devise_invalidatable/model')

module DeviseInvalidatable
end

if defined?(ActiveRecord)
  class UserSession < ActiveRecord::Base
    belongs_to :sessionable, polymorphic: true
    def self.deactivate(session_id)
      where(session_id: session_id).delete_all
    end
    
    def location
      "San Jose"
    end
    
    def devise
      "desktop" # tablet, phone
    end
    
    def browser
      "Chrome"
    end
    
    def current?(session_id)
      self.session_id == session_id
    end
  end
end
