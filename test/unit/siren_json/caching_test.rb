require 'siren_test_helper'

describe 'HyperResource caching' do
  class TestAPI < HyperResource; end

  before do
    @rsrc = TestAPI.new(
      :root => 'http://example.com',
      :adapter => HyperResource::Adapter::SIREN_JSON
    )
    @rsrc.adapter.apply(SIREN_BODY, @rsrc)
  end

  it 'can be dumped with Marshal.dump' do
    dump = Marshal.dump(@rsrc)
    new_rsrc = Marshal.load(dump)
    assert new_rsrc.page
  end
end
