module Puppet::Parser::Functions
    newfunction(:hash_keys, :type => :rvalue) do |args|
        keys = []
        args[0].each do |k, v|
            keys << k
        end
        return keys
    end
end
