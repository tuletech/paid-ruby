require File.expand_path('../../test_helper', __FILE__)

module Paid
  class MetadataTest < Test::Unit::TestCase
    setup do
      @metadata_supported = {
        :transaction => {
          :new => Paid::Transaction.method(:new),
          :test => method(:test_transaction),
          :url => "/v0/transactions/#{test_transaction()[:id]}"
        },
        :customer => {
          :new => Paid::Customer.method(:new),
          :test => method(:test_customer),
          :url => "/v0/customers/#{test_customer()[:id]}"
        }
      }

      @base_url = 'https://api.paidapi.com'
    end

    should "not touch metadata" do
      update_actions = lambda {|obj| obj.description = 'test'}
      check_metadata({:metadata => {'initial' => 'true'}},
                    'description=test',
                    update_actions)
    end


    should "update metadata as a whole" do
      update_actions = lambda {|obj| obj.metadata = {'uuid' => '6735'}}
      check_metadata({:metadata => {}},
                    'metadata[uuid]=6735',
                    update_actions)

      if is_greater_than_ruby_1_9?
        check_metadata({:metadata => {:initial => 'true'}},
                      'metadata[uuid]=6735&metadata[initial]=',
                      update_actions)
      end
    end

    should "update metadata keys individually" do
      update_actions = lambda {|obj| obj.metadata['txn_id'] = '134a13'}
      check_metadata({:metadata => {'initial' => 'true'}},
                     'metadata[txn_id]=134a13',
                     update_actions)
    end

    should "clear metadata as a whole" do
      update_actions = lambda {|obj| obj.metadata = nil}
      check_metadata({:metadata => {'initial' => 'true'}},
                     'metadata=',
                     update_actions)
    end

    should "clear metadata keys individually" do
      update_actions = lambda {|obj| obj.metadata['initial'] = nil}
      check_metadata({:metadata => {'initial' => 'true'}},
                     'metadata[initial]=',
                     update_actions)
    end

    should "handle combinations of whole and partial metadata updates" do
      if is_greater_than_ruby_1_9?
        update_actions = lambda do |obj|
          obj.metadata = {'type' => 'summer'}
          obj.metadata['uuid'] = '6735'
        end
        params = {:metadata => {'type' => 'summer', 'uuid' => '6735'}}
        curl_args = Paid.uri_encode(params)
        check_metadata({:metadata => {'type' => 'christmas'}},
                       curl_args,
                       update_actions)
      end
    end

    def check_metadata (initial_params, curl_args, metadata_update)
      @metadata_supported.each do |name, methods|
        neu = methods[:new]
        test = methods[:test]
        url = @base_url + methods[:url]

        initial_test_obj = test.call(initial_params)
        @mock.expects(:get).once.returns(test_response(initial_test_obj))

        final_test_obj = test.call()
        @mock.expects(:post).once.
          returns(test_response(final_test_obj)).
          with(url, nil, curl_args)

        obj = neu.call("test")
        obj.refresh()
        metadata_update.call(obj)
        obj.save
      end
    end

    def is_greater_than_ruby_1_9?
      version = RUBY_VERSION.dup  # clone preserves frozen state
      Gem::Version.new(version) >= Gem::Version.new('1.9')
    end
  end
end