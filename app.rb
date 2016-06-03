require 'bundler/setup'
Bundler.require
Dotenv.load

require 'open-uri'
require 'json'

enable :sessions

helpers do
  def consumer
    @consumer ||= OAuth::Consumer.new(ENV['WIKIMEDIA_CONSUMER_TOKEN'],  ENV['WIKIMEDIA_SECRET_TOKEN'], site: 'https://www.wikidata.org')
  end

  def auth_token
    session[:wikidata_credentials][:token]
  end

  def auth_secret
    session[:wikidata_credentials][:secret]
  end

  def access_token
    @access_token ||= OAuth::AccessToken.new(consumer, auth_token, auth_secret)
  end

  def signed_in?
    session.key?(:wikidata_credentials)
  end
end

use OmniAuth::Builder do
  provider :mediawiki, ENV['WIKIMEDIA_CONSUMER_TOKEN'], ENV['WIKIMEDIA_SECRET_TOKEN'], client_options: { site: 'https://www.wikidata.org' }
end

get '/' do
  if signed_in?
    erb :index
  else
    '<a href="/auth/mediawiki">Sign in</a>'
  end
end

# TODO: Don't hardcode Q839078 here.
get '/query' do
  content_type 'application/json; charset=utf-8'
  uri = URI.parse('https://query.wikidata.org/sparql')
  sparql = '
  SELECT ?item ?itemLabel ?start ?end
    WHERE
    {
      ?item wdt:P31 wd:Q5 .
      ?item p:P39 ?position_held_statement .
      ?position_held_statement ps:P39 wd:Q839078 .
      OPTIONAL { ?position_held_statement pq:P580 ?start . }
      OPTIONAL { ?position_held_statement pq:P582 ?end . }
      SERVICE wikibase:label { bd:serviceParam wikibase:language "en" . }
    } ORDER BY ?start
  '
  uri.query = URI.encode_www_form(query: sparql, format: 'json')
  open(uri.to_s).read
end

get '/auth/mediawiki/callback' do
  auth = env['omniauth.auth']
  session[:wikidata_credentials] = auth.credentials
  redirect to('/')
end
