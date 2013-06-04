module RSpec
  module Matchers
    class AllowMassAssignmentOf # :nodoc:
      def initialize hash = nil
        raise if hash.nil?
        raise unless hash.kind_of? Hash
        raise unless hash.length > 0
        @attributes = hash
      end

      def matches? model
        old = {}
        @attributes.each do |key, val|
          current = model.send(key.to_s)
          raise if val == current
          old[key] = current
        end
        model.update_attributes(@attributes)
        @attributes.keys.all? do |key|
          model.send(key.to_s) != old[key]
        end
      end

      def failure_message
        "expected mass assignment to #{self.keys_as_string} to succeed but it did not"
      end

      def negative_failure_message
        "expected mass assignment to #{self.keys_as_string} to fail but it did not"
      end

      def description
        "allow mass assignment to #{self.keys_as_string}"
      end

      def keys_as_string
        @attributes.keys.join(', ')
      end
    end # class AllowMassAssignmentFor

    def allow_mass_assignment_of hash = nil
      AllowMassAssignmentOf.new hash
    end
  end # module Matchers
end # module RSpec