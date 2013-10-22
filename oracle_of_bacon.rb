require 'debugger'              # optional, may be helpful
require 'open-uri'              # allows open('http://...') to return body
require 'cgi'                   # for escaping URIs
require 'nokogiri'              # XML parser
require 'active_model'          # for validations

class OracleOfBacon

  class InvalidError < RuntimeError ; end
  class NetworkError < RuntimeError ; end
  class InvalidKeyError < RuntimeError ; end

  attr_accessor :from, :to
  attr_reader :api_key, :response, :uri
  
  include ActiveModel::Validations
  validates_presence_of :from
  validates_presence_of :to
  validates_presence_of :api_key
  validate :from_does_not_equal_to

  def from_does_not_equal_to
    errors.add(:base, "From cannot be the same as To") unless @from != @to 
  end

  def initialize(api_key='38b99ce9ec87')
       @from = 'Kevin Bacon'      
       @to = 'Kevin Bacon'
       @api_key = api_key
  end

  def find_connections
    make_uri_from_arguments
    begin
      xml = URI.parse(uri).read
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
      Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
      Net::ProtocolError => e
      # convert all of these into a generic OracleOfBacon::NetworkError,
      #  but keep the original error message
      raise OracleOfBacon::NetworkError
    end
    # your code here: create the OracleOfBacon::Response object
    OracleOfBacon::Response.new(xml)
  end

  def make_uri_from_arguments
    # your code here: set the @uri attribute to properly-escaped URI
    #   constructed from the @from, @to, @api_key arguments
    params = {}
    params["p"] = @api_key
    params["a"] = @from
    params["b"] = @to
    query = URI.encode_www_form(params)
    host = 'oracleofbacon.org'
    path = '/cgi-bin/xml'
    @uri = URI::HTTP.build([nil, host, nil, path, query, nil]).to_s
  end
      
  class Response
    attr_reader :type, :data
    # create a Response object from a string of XML markup.
    def initialize(xml)
      @doc = Nokogiri::XML(xml)
      parse_response
    end

    private

    def parse_response
      if ! @doc.xpath('/error').empty?
        parse_error_response	
      # your code here: 'elsif' clauses to handle other responses
      elsif ! @doc.xpath('/link').empty?
        parse_graph_response
      elsif ! @doc.xpath('/spellcheck').empty?
        parse_spellcheck_response
      else	
      # for responses not matching the 3 basic types, the Response
      # object should have type 'unknown' and data 'unknown response'   
      @type = :unknown
      @data = 'unknown response type'
      end
    end
    def parse_error_response
      @type = :error
      @data = 'Unauthorized access'
    end
    def parse_graph_response
      @type = :graph
      actor_arr = @doc.xpath('//actor').map(&:text)
      movie_arr = @doc.xpath('//movie').map(&:text)
      @data = actor_arr.zip(movie_arr).flatten.compact
    end
    def parse_spellcheck_response
      @type = :spellcheck
      match_arr = @doc.xpath('//match').map(&:text)
      @data = match_arr.flatten.compact
    end
  end
end

