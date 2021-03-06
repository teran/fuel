# require 'ipaddr'
# require 'yaml'
# require 'json'

class MrntQuantumFA
  def initialize(scope, cfg)
    @scope = scope
    @quantum_config = cfg
  end

  #class method
  def self.sanitize_array(aa)
    aa.reduce([]) do |rv, v|
      rv << case v.class
          when Hash  then sanitize_hash(v)
          when Array  then sanitize_array(v)
          else v
      end
    end
  end

  #class method
  def self.sanitize_hash(hh)
    rv = {}
    hh.each do |k, v|
      rv[k.to_sym] = case v.class.to_s
        when "Hash"  then sanitize_hash(v)
        when "Array" then sanitize_array(v)
        else v
      end
    end
    return rv
  end

  def get_pool_size()
    floating_range = @quantum_config[:predefined_networks][:net04_ext][:L3][:floating]
    Puppet::debug("Floating range is #{floating_range}")
    borders = floating_range.split(':').map{|x| x.split('.')[-1].to_i}
    rv = borders[1]-borders[0]
    if rv <= 4
      return 0
    elsif rv > 10
      rv = 10
    else
      rv = (rv / 2).to_i - 1
    end
    return rv
  end
end

module Puppet::Parser::Functions
  newfunction(:get_floatingip_pool_size_for_admin, :type => :rvalue, :doc => <<-EOS
    This function get Hash of Quantum configuration
    and calculate autogenerated floating IPs pool size for admin tenant.

    Example call:
    $pool_size = get_floatingip_pool_size_for_admin($quantum_settings_hash)

    EOS
  ) do |argv|
    #Puppet::Parser::Functions.autoloader.loadall
    nr_conf = MrntQuantumFA.new(self, MrntQuantumFA.sanitize_hash(argv[0]))
    nr_conf.get_pool_size()
  end
end
# vim: set ts=2 sw=2 et :