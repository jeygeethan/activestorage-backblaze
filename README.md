This is a gem for using backblaze with activestorage.

Usage:

gem 'activestorage-backblaze'

Then in your storage.yml, use the following

backblaze:
  service: Backblaze
  bucket_name: <bucket_name>
  bucket_id: <bucket_id>
  key_id: <keyId>
  key_token: <keyToken>


In your environments/production.rb or application.rb (depending on your choice) add the following:

config.active_storage.service = :backblaze
