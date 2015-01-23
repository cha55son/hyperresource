require 'siren_test_helper'

describe "Embedded Resources" do
  class SirenTestAPI < HyperResource 
    self.root = 'http://example.com'
    self.adapter = HyperResource::Adapter::SIREN_JSON
  end

  it 'supports an array of embedded resources' do
    hyper = SirenTestAPI.new
    hyper.objects.class.to_s.must_equal 'SirenTestAPI::Objects'
    body = { 
      'class' => ['messages', 'collection'],
      'entities' => [
        {
          'class' => ['messages'],
          'rel' => ['messages'],
          'properties' => {
            'name' => 'test1'
          },
          'links' => [
            {
              'rel' => ['self'],
              'href' => '/messages/1'
            }
          ]
        }
      ],
      'links' => [
        {
          'rel' => ['self'],
          'href' => '/messages'
        }
      ]
    }
    hyper.adapter.apply(body, hyper)
    hyper.messages.must_be_instance_of Array
    hyper.messages.first.href.must_equal '/messages/1'
  end

  # I don't think siren supports this. It must be an array.
  # it 'supports a single embedded resource' do
  #
  # end
end
