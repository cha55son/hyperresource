require 'test_helper'

content_type = 'application/vnd.dummy.siren+json;'
stub_connection = Faraday.new do |builder|
  builder.adapter :test do |stub|
    stub.get('/') {[ 200, {'Content-type' => content_type + 'type=Root'},
      <<-EOT
{ 
  "links": [ 
    { "rel": ["self"], "href": "/" },
    { "rel": ["dummies"], "href": "/dummies" }
  ]
}
      EOT
    ]}

    joe_dummy = <<-EOT
{ 
  "properties": {
    "first_name": "Joe", 
    "last_name": "Dummy"
  },
  "actions": [],
  "links": [
    { "rel": ["self"], "href": "/dummies/1" }
  ]
}
    EOT

    stub.get('/dummies')   {[ 200, {'Content-type' => content_type + 'type=Dummies'},
      <<-EOT
{ 
  "entities": [ #{joe_dummy} ],
  "actions": [],
  "links": [
    { "rel": ["self"], "href": "/dummies" }
  ]
}
      EOT
    ]}

    stub.post('/dummies') {[
      201,
      { 'Content-type' => content_type + 'type=Dummies',
        'Location' => '/dummies/1'},
      joe_dummy
    ]}

    stub.get('/dummies/1') {[
      200,
      {'Content-type' => content_type + 'type=Dummy'},
      joe_dummy
    ]}

    stub.put('/dummies/1') {[
      200,
      {'Content-type' => content_type + 'type=Dummy'},
      joe_dummy
    ]}

    stub.patch('/dummies/1') {[
      200,
      {'Content-type' => content_type + 'type=Dummy'},
      joe_dummy
    ]}

    stub.delete('/dummies/1') {[
      200,
      {'Content-type' => content_type},
      ''
    ]}

    stub.get('/404') {[
      404,
      {'Content-type' => content_type + 'type=Error'},
      '{"class": ["error"], "title": "Not found"}'
    ]}

    stub.get('/500') {[
      500,
      {'Content-type' => content_type + 'type=Error'},
      '{"class": ["error"], "title": "Internal server error"}'
    ]}

    stub.get('/garbage') {[
      200,
      {'Content-type' => 'application/json'},
      '!@#$%!@##%$!@#$%^  (This is very invalid JSON)'
    ]}
  end
end

describe HyperResource::Modules::HTTP do
  class DummyAPI < HyperResource
    class Link < HyperResource::Link
    end
  end

  before do
    DummyAPI::Link.any_instance.stubs(:faraday_connection).returns(stub_connection)
  end

  describe 'GET' do
    it 'works at a basic level' do
      hr = DummyAPI.new({
        :root => 'http://example.com/', 
        :adapter => HyperResource::Adapter::SIREN_JSON
      })
      byebug
      root = hr.get
      root.wont_be_nil
      root.must_be_kind_of HyperResource
      root.must_be_instance_of DummyAPI::Root
      root.links.must_be_instance_of DummyAPI::Root::Links
      assert root.links.dummies
    end

    it 'raises client error' do
      hr = DummyAPI.new({
        :root => 'http://example.com/', 
        :href => '404',
        :adapter => HyperResource::Adapter::SIREN_JSON
      })
      begin
        hr.get
        assert false # shouldn't get here
      rescue HyperResource::ClientError => e
        e.response.wont_be_nil
      end
    end

    it 'raises server error' do
      hr = DummyAPI.new({
        :root => 'http://example.com/', 
        :href => '500',
        :adapter => HyperResource::Adapter::SIREN_JSON
      })
      begin
        hr.get
        assert false # shouldn't get here
      rescue HyperResource::ServerError => e
        e.response.wont_be_nil
      end
    end

    it 'raises response error' do
      hr = DummyAPI.new({
        :root => 'http://example.com/', 
        :href => 'garbage',
        :adapter => HyperResource::Adapter::SIREN_JSON
      })
      begin
        hr.get
        assert false # shouldn't get here
      rescue HyperResource::ResponseError => e
        e.response.wont_be_nil
        e.cause.must_be_kind_of Exception
      end
    end

  end
end
