module Cyclop
  module Spec
    module Action
      class Email < Cyclop::Action
        def self.queues
          ["slow"]
        end

        def self.perform(to, kind)
        end
      end
    end
  end
end