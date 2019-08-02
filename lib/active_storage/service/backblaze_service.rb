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
      logger: Rails.logger
    )
  end

  def upload(key, io, checksum: nil, **options)
    instrument :upload, { key: key, checksum: checksum } do
      begin
        io.binmode
        io.rewind
        @connection.put_object(@bucket_name, key, io.read)
      rescue => e
        puts "ERROR - 101"
        puts e.inspect
        raise ActiveStorage::IntegrityError
      end
    end
  end

  def download(key, &block)
    if block_given?
      instrument :streaming_download, { key: key } do
        stream(key, &block)
      end
    else
      instrument :download, { key: key } do
        resp = @connection.get_object(@bucket_name, key)
        io = StringIO.new(resp.body)
        io
      end
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
    instrument :url, { key: key} do |payload|
      result = @connection.b2_get_upload_url(@bucket_name)
      url = result["uploadUrl"]
      payload[:url] = url
      url
    end
  end

  def headers_for_direct_upload(key, content_type:, checksum:, content_length:, **options)
    result = @connection.b2_get_upload_url(@bucket_name)
    { 'Authorization' => result["authorizationToken"], 'X-Bz-File-Name' => key, 'Content-Type' => content_type, 'Content-Length' => content_length, 'X-Bz-Content-Sha1' => 'do_not_verify' }
  end

  private
    def stream(key, options = {}, &block)
      resp = @connection.get_object(@bucket_name, key)
      io = StringIO.new(resp.body)
      io.binmode

      chunk_size = 5.megabytes

      while chunk = io.read(chunk_size)
        yield chunk
      end
    end

end

class Fog::Backblaze::Storage::Real
  def b2_get_upload_url(bucket_name)
    upload_url = @token_cache.fetch("upload_url/#{bucket_name}") do
      bucket_id = _get_bucket_id!(bucket_name)
      result = b2_command(:b2_get_upload_url, body: {bucketId: bucket_id})
      result.json
    end
    upload_url
  end
end
