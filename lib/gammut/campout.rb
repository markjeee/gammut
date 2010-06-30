module Gammut
  module Campout
    module Controllers
      class Hello < REST()
        include Tweetitow::CampoutControllerHelper

        def index
          respond "Hello World!"
        end
      end
    end
  end
end
