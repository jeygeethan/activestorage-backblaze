This is a gem for using backblaze with activestorage.

### Note:

Since this was created before backblaze supported S3 apis, this gem was relevant back then. But now you can directly use the S3 endpoints with Backblaze B2 and skip this gem

Readmore: https://github.com/jeygeethan/activestorage-backblaze/issues/4



# Usage:

```ruby
gem 'activestorage-backblaze'
```

Then in your storage.yml, use the following

```yaml
backblaze:
  service: Backblaze
  bucket_name: <bucket_name>
  bucket_id: <bucket_id>
  key_id: <keyId>
  key_token: <keyToken>
```

In your environments/production.rb or application.rb (depending on your choice) add the following:

```ruby
config.active_storage.service = :backblaze
```

------

# Javascript Usage

### Corresponding git repos

https://github.com/jeygeethan/actiontext-backblaze
https://github.com/jeygeethan/activestorage-backblaze-javascript

Add this to your package.json

```"@jeygeethan/actiontext-backblaze": "^6.1.3-alpha"```

This includes the activestorage-backblaze npm package as a dependency. Javascript is needed for direct uploads and use in Trix editor.

