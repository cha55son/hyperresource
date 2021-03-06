require 'faraday'
require 'uri'
require 'json'
require 'digest/md5'

class HyperResource

  ## Returns this resource's fully qualified URL.  Returns nil when
  ## `root` or `href` are malformed.
  def url
    begin
      URI.join(self.root, (self.href || '')).to_s
    rescue StandardError
      nil
    end
  end


  ## Performs a GET request to this resource's URL, and returns a
  ## new resource representing the response.
  def get
    to_link.get
  end

  ## Performs a POST request to this resource's URL, sending all of
  ## `attributes` as a request body unless an `attrs` Hash is given.
  ## Returns a new resource representing the response.
  def post(attrs=nil)
    to_link.post(attrs)
  end

  ## Performs a PUT request to this resource's URL, sending all of
  ## `attributes` as a request body unless an `attrs` Hash is given.
  ## Returns a new resource representing the response.
  def put(*args)
    to_link.put(*args)
  end

  ## Performs a PATCH request to this resource's URL, sending
  ## `attributes.changed_attributes` as a request body
  ## unless an `attrs` Hash is given.  Returns a new resource
  ## representing the response.
  def patch(*args)
    self.to_link.patch(*args)
  end

  ## Performs a DELETE request to this resource's URL.  Returns a new
  ## resource representing the response.
  def delete(*args)
    to_link.delete(*args)
  end

  ## Creates a Link representing this resource.  Used for HTTP delegation.
  # @private
  def to_link(args={})
    self.class::Link.new(self,
                         :href => args[:href] || self.href,
                         :params => args[:params] || self.attributes)
  end



  # @private
  def create(attrs)
    _hr_deprecate('HyperResource#create is deprecated. Please use '+
                  '#post instead.')
    to_link.post(attrs)
  end

  # @private
  def update(*args)
    _hr_deprecate('HyperResource#update is deprecated. Please use '+
                  '#put or #patch instead.')
    to_link.put(*args)
  end

  module Modules

    ## HyperResource::Modules::HTTP is included by HyperResource::Link.
    ## It provides support for GET, POST, PUT, PATCH, and DELETE.
    ## Each method returns a new object which is a kind_of HyperResource.
    module HTTP

      ## Loads and returns the resource pointed to by +href+.  The returned
      ## resource will be blessed into its "proper" class, if
      ## +self.class.namespace != nil+.
      def get
        ## Adding default_attributes to URL query params is not automatic
        url = FuzzyURL.new(self.url || '')
        query_str = url[:query] || ''
        query_attrs = Hash[ query_str.split('&').map{|p| p.split('=')} ]
        attrs = (self.resource.default_attributes || {}).merge(query_attrs)
        attrs_str = attrs.inject([]){|pairs,(k,v)| pairs<<"#{k}=#{v}"}.join('&')
        if attrs_str != ''
          url = FuzzyURL.new(url.to_hash.merge(:query => attrs_str))
        end
        response = faraday_connection.get(url.to_s)
        new_resource_from_response(response)
      end

      ## By default, calls +post+ with the given arguments. Override to
      ## change this behavior.
      def create(*args)
        _hr_deprecate('HyperResource::Link#create is deprecated. Please use '+
                      '#post instead.')
        post(*args)
      end

      ## POSTs the given attributes to this resource's href, and returns
      ## the response resource.
      def post(attrs=nil)
        attrs ||= self.resource.attributes
        attrs = (self.resource.default_attributes || {}).merge(attrs)
        response = faraday_connection.post do |req|
          req.body = self.resource.adapter.serialize(attrs)
        end
        new_resource_from_response(response)
      end

      ## By default, calls +puwt+ with the given arguments.  Override to
      ## change this behavior.
      def update(*args)
        _hr_deprecate('HyperResource::Link#update is deprecated. Please use '+
                      '#put or #patch instead.')
        put(*args)
      end

      ## PUTs this resource's attributes to this resource's href, and returns
      ## the response resource.  If attributes are given, +put+ uses those
      ## instead.
      def put(attrs=nil)
        attrs ||= self.resource.attributes
        attrs = (self.resource.default_attributes || {}).merge(attrs)
        response = faraday_connection.put do |req|
          req.body = self.resource.adapter.serialize(attrs)
        end
        new_resource_from_response(response)
      end

      ## PATCHes this resource's changed attributes to this resource's href,
      ## and returns the response resource.  If attributes are given, +patch+
      ## uses those instead.
      def patch(attrs=nil)
        attrs ||= self.resource.attributes.changed_attributes
        attrs = (self.resource.default_attributes || {}).merge(attrs)
        response = faraday_connection.patch do |req|
          req.body = self.resource.adapter.serialize(attrs)
        end
        new_resource_from_response(response)
      end

      ## DELETEs this resource's href, and returns the response resource.
      def delete
        response = faraday_connection.delete
        new_resource_from_response(response)
      end

    private

      ## Returns a raw Faraday connection to this resource's URL, with proper
      ## headers (including auth).  Threadsafe.
      def faraday_connection(url=nil)
        rsrc = self.resource
        url ||= self.url
        headers = rsrc.headers_for_url(url) || {}
        auth = rsrc.auth_for_url(url) || {}

        key = ::Digest::MD5.hexdigest({
          'faraday_connection' => {
            'url' => url,
            'headers' => headers,
            'ba' => auth[:basic]
          }
        }.to_json)
        return Thread.current[key] if Thread.current[key]

        fo = rsrc.faraday_options_for_url(url) || {}
        fc = Faraday.new(fo.merge(:url => url))
        fc.headers.merge!('User-Agent' => rsrc.user_agent)
        fc.headers.merge!(headers)
        if ba=auth[:basic]
          fc.basic_auth(*ba)
        end
        Thread.current[key] = fc
      end


      ## Given a Faraday::Response object, create a new resource
      ## object to represent it.  The new resource will be in its
      ## proper class according to its configured `namespace` and
      ## the response's detected data type.
      def new_resource_from_response(response)
        status = response.status
        is_success = (status / 100 == 2)
        adapter = self.resource.adapter || HyperResource::Adapter::HAL_JSON

        body = nil
        begin
          if response.body
            body = adapter.deserialize(response.body)
          end
        rescue StandardError => e
          if is_success
            raise HyperResource::ResponseError.new(
              "Error when deserializing response body",
              :response => response,
              :cause => e
            )
          end
        end

        new_rsrc = resource.new_from(:link => self,
                                     :body => body,
                                     :response => response)

        if status / 100 == 2
          return new_rsrc
        elsif status / 100 == 3
          raise NotImplementedError,
            "HyperResource has not implemented redirection."
        elsif status / 100 == 4
          raise HyperResource::ClientError.new(status.to_s,
                                               :response => response,
                                               :body => body)
        elsif status / 100 == 5
          raise HyperResource::ServerError.new(status.to_s,
                                               :response => response,
                                               :body => body)
        else ## 1xx? really?
          raise HyperResource::ResponseError.new("Unknown status #{status}",
                                                 :response => response,
                                                 :body => body)

        end
      end

    end
  end
end

