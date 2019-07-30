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
    @connection.put_object(@bucket_name, "myfile1", "THISISATESTFILE").json
  end
end