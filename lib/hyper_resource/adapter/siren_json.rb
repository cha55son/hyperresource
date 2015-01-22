require 'rubygems' if RUBY_VERSION[0..2] == '1.8'
require 'json'

class HyperResource
  class Adapter
    class SIREN_JSON < Adapter
      class << self

        def serialize(object)
          JSON.dump(object)
        end

        def deserialize(string)
          JSON.parse(string)
        end

        def apply(response, resource, opts={})
          if !response.kind_of?(Hash)
            raise ArgumentError, "'response' argument must be a Hash (got #{response.inspect})"
          end
          if !resource.kind_of?(HyperResource)
            raise ArgumentError, "'resource' argument must be a HyperResource (got #{resource.inspect})"
          end

          apply_objects(response, resource)
          apply_links(response, resource)
          # apply_attributes(response, resource)
          resource.loaded = true
          resource.href = response['links']['self']['href'] rescue nil
          resource
        end


      private

        def apply_objects(resp, rsrc)
          return unless resp['entities']
          objs = rsrc.objects

          resp['entities'].each do |entity|
            next unless entity.is_a? Hash
            objs[entity['title'] || ''] = rsrc.new_from({
              :resource => rsrc,
              :body => entity,
              :href => (entity['links']['self']['href'] rescue nil)
            })
          end
        end


        def apply_links(resp, rsrc)
          return unless resp['links']
          links = rsrc.links

          resp['links'].each do |link_spec|
            next unless link_spec.is_a? Hash
            links[link_spec['rel'][0] || ''] = new_link_from_spec(rsrc, link_spec)
          end
        end

        def new_link_from_spec(resource, link_spec)
          resource.class::Link.new(resource, link_spec)
        end


      #   def apply_attributes(resp, rsrc)
      #     given_attrs = resp.reject{|k,v| %w(_links _embedded).include?(k)}
      #     filtered_attrs = rsrc.incoming_body_filter(given_attrs)

      #     filtered_attrs.keys.each do |attr|
      #       rsrc.attributes[attr] = filtered_attrs[attr]
      #     end

      #     rsrc.attributes._hr_clear_changed
      #   end

      end
    end
  end
end
