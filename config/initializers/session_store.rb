# Configure the Rails cookie session store. Adjust SameSite and Secure options for local development
# so browser will send the session cookie on OAuth POST/redirect flows.

Rails.application.config.session_store :cookie_store,
  key: '_aura_session',
  same_site: (Rails.env.production? ? :none : :lax),
  secure: Rails.env.production?

# Notes:
# - same_site: :lax allows cookies on top-level GET navigations and POSTs from same site; it's a
#   reasonable default for apps that need cross-origin redirects (OAuth providers).
# - secure: true requires HTTPS; setting secure: Rails.env.production? ensures local HTTP dev
#   will send cookies while production remains secure.
