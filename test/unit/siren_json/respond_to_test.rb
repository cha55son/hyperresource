require 'siren_test_helper'

describe HyperResource do
  class SirenNoMethodsAPI < HyperResource; end

  before do
    @api = SirenNoMethodsAPI.new(
      :root => 'http://example.com',
      :adapter => HyperResource::Adapter::SIREN_JSON
    )
    @api.adapter.apply(SIREN_BODY, @api)
  end

  describe 'respond_to' do
    it "doesn't create methods" do
      @api.methods.wont_include(:page)
      @api.attributes.methods.wont_include(:page)
      @api.methods.wont_include(:graphs)
      @api.objects.methods.wont_include(:graphs)
      @api.methods.wont_include(:next)
      @api.links.methods.wont_include(:next)

      # Need to add actions here
    end

    it "responds_to the right things" do
      @api.must_respond_to(:page)
      @api.attributes.must_respond_to(:page)
      @api.must_respond_to(:graphs)
      @api.objects.must_respond_to(:graphs)
      @api.must_respond_to(:next)
      @api.links.must_respond_to(:next)

      # Need to add actions here
    end
  end
end
