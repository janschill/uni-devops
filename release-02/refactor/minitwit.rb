require 'roda'

module MiniTwit
  class App < Roda
    plugin :render
    plugin :hooks


    route do |r|
      # TODO: Fix Message method to also fetch followed messages
      r.root do
        @options = {
          'page_title' => 'My timeline',
          'request_endpoint' => 'timeline'
        }
        view('timeline')
      end

      r.get 'public' do
        @options = {
          'page_title' => 'Public timeline'
        }
        view('timeline')
      end

        view('timeline')
    end
  end
end
