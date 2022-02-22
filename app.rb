require "sinatra"
require 'bundler/setup'
require 'aws-sdk-s3'

set :port, 9494

ENDPOINT = ENV['BACKUP_S3_URL']
BUCKET_ID = ENV['BACKUP_S3_BUCKET']

S3 = Aws::S3::Client.new(
  region: ENV['BACKUP_S3_REGION'],
  credentials: Aws::Credentials.new(
    ENV['BACKUP_S3_ACCESS_KEY'],
    ENV['BACKUP_S3_ACCESS_SECRET']
  ),
  endpoint: ENDPOINT
)

SIGNER = Aws::S3::Presigner.new(client: S3)

get '/' do
  haml :index, locals: ls
end

get '/browse' do
  haml :index, locals: ls(dir: params[:dir])
end

def ls(dir: '')
  resp = S3.list_objects(bucket: BUCKET_ID, prefix: dir, delimiter: '/')

  {
    folders: folders(resp),
    files: files(resp)
  }
end

def folders(s3_response)
  s3_response.data.common_prefixes.map do |folder|
    folder.prefix
  end
end

def files(s3_response)
  s3_response.contents.map do |object|
    url, headers = SIGNER.presigned_request(
      :get_object, bucket: BUCKET_ID, key: object.key
    )

    {
      key: object.key,
      url: url
    }
  end
end
