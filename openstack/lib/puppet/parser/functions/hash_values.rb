module Puppet::Parser::Functions
    newfunction(:hash_values, :type => :rvalue) do |args|
        values = []
        args[0].each do |k, v|
            values << v
        end
        return values
    end
end
