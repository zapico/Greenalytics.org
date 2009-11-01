# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_greenanalytics_session',
  :secret      => '775cec7f2b06a98c873d2010f352a8021ee4e26689eb8a53107c031a99c640ffde51b8cc6050cb9c296d0ec7a86f1d5a4ec20e0c4924b7613498c18d2d42dd0b'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
