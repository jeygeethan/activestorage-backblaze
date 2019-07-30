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
    )
  end

  def upload(key, io, checksum: nil)
    instrument :upload, key, checksum: checksum do
      begin
        @connection.put_object(@bucket_name, key, io)
      rescue => e
        raise ActiveStorage::IntegrityError
      end
    end
  end

  def download(key)
    if block_given?
      instrument :streaming_download, key do
        stream(key, &block)
      end
    else
      instrument :download, key do
        _, io = blobs.get_blob(container, key)
        io.force_encoding(Encoding::BINARY)
      end
    end
  end

  def delete(key)
    instrument :delete, key do
      begin
        blobs.delete_blob(container, key)
      rescue Azure::Core::Http::HTTPError
        false
      end
    end
  end

  def exist?(key)
    instrument :exist, key do |payload|
      answer = blob_for(key).present?
      payload[:exist] = answer
      answer
    end
  end

  def url(key, expires_in:, disposition:, filename:)
    instrument :url, key do |payload|
      base_url = url_for(key)
      generated_url = signer.signed_uri(URI(base_url), false, permissions: "r",
        expiry: format_expiry(expires_in), content_disposition: "#{disposition}; filename=\"#{filename}\"").to_s

      payload[:url] = generated_url

      generated_url
    end
  end

  def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:)
    instrument :url, key do |payload|
      base_url = url_for(key)
      generated_url = signer.signed_uri(URI(base_url), false, permissions: "rw",
        expiry: format_expiry(expires_in)).to_s

      payload[:url] = generated_url

      generated_url
    end
  end

  def headers_for_direct_upload(key, content_type:, checksum:, **)
    { "Content-Type" => content_type, "Content-MD5" => checksum, "x-ms-blob-type" => "BlockBlob" }
  end

  private
    def url_for(key)
      "#{path}/#{container}/#{key}"
    end

    def blob_for(key)
      blobs.get_blob_properties(container, key)
    rescue Azure::Core::Http::HTTPError
      false
    end

    def format_expiry(expires_in)
      expires_in ? Time.now.utc.advance(seconds: expires_in).iso8601 : nil
    end

    # Reads the object for the given key in chunks, yielding each to the block.
    def stream(key, options = {}, &block)
      blob = blob_for(key)

      chunk_size = 5.megabytes
      offset = 0

      while offset < blob.properties[:content_length]
        _, io = blobs.get_blob(container, key, start_range: offset, end_range: offset + chunk_size - 1)
        yield io
        offset += chunk_size
      end
    end
end