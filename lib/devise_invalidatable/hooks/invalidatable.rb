# After authenticating, we’re removing any session activation that may already
# exist, and creating a new session# activation. We generate our own random id
# (in User#activate_session) and store it in the auth_id key. There is already
# a session_id key, but the session gets renewed (and the session id changes)
# after authentication in order to avoid session fixation attacks. So it’s
# easier to just use our own id.
Warden::Manager.after_set_user except: :fetch do |user, warden, options|
  auth_id =  "#{options[:scope]}_auth_id"
  UserSession.deactivate(warden.raw_session[auth_id])
  warden.raw_session[auth_id] = user.activate_session(warden, options)
end

# After fetching a user from the session, we check that the session is marked
# as active for that user. If it’s not we log the user out.
Warden::Manager.after_fetch do |user, warden, options|
  auth_id =  "#{options[:scope]}_auth_id"
  user_session = user.user_sessions.find_by(session_id: warden.raw_session[auth_id])
  if user_session.present?
    # update activity timestamp every hour
    user_session.touch if user_session.updated_at < 1.hour.ago
  else
    warden.logout(options[:scope])
    throw :warden, message: :unauthenticated
  end
end

# When logging out, we deactivate the current session. This ensures that the
# session cookie can’t be reused afterwards.
Warden::Manager.before_logout do |_, warden, options|
  auth_id =  "#{options[:scope]}_auth_id"
  UserSession.deactivate(warden.raw_session[auth_id])
end
