require "fog/backblaze"

class ActiveStorage::Service::BackblazeService < ActiveStorage::Service
  def initialize(key_id:, key_token:, bucket_name:, bucket_id:)
    @key_id = key_id
    @key_token = key_token
    @bucket_name = bucket_name
    @bucket_id = bucket_id
    @connection = Fog::Storage.new(
      provider: 'backblaze',
      b2_key_id: @key_id,
      b2_key_token: @key_token,
      b2_bucket_name: @bucket_name,
      b2_bucket_id: @bucket_id,
      logger: Logger.new(STDOUT)
    )
  end

  def upload(key, io, checksum: nil, **options)
    instrument :upload, { key: key, checksum: checksum } do
      begin
        @connection.put_object(@bucket_name, key, io)
      rescue => e
        raise ActiveStorage::IntegrityError
      end
    end
  end

  def download(key)
    instrument :download, { key: key } do
      io = @connection.get_object(@bucket_name, key)
    end
  end

  def delete(key)
    instrument :delete, { key: key } do
      begin
        @connection.delete_object(@bucket_name, key)
      rescue => e
        false
      end
    end
  end

  def delete_prefixed(prefix)
    delete(prefix)
  end

  def exist?(key)
    instrument :exist, { key: key } do |payload|
      answer = false
      begin
        @connection.head_object(@bucket_name, key)
        answer = true
      rescue => e
      end
      payload[:exist] = answer
      answer
    end
  end

  def url(key, expires_in:, disposition:, filename:, **options)
    instrument :url, {key: key} do |payload|
      url = @connection.get_public_object_url(@bucket_name, key)
      payload[:url] = url

      url
    end
  end

  def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:)
    raise NotImpletementedError
  end

  def headers_for_direct_upload(key, content_type:, checksum:, **)
    raise NotImpletementedError
  end

end
