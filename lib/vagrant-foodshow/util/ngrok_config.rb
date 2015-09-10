module VagrantPlugins
  module Foodshow
    module Util
      class NgrokConfig
        NGROK_ALLOWED_OPTIONS = %w(authtoken hostname auth proto subdomain host port server_addr trust_host_root_certs)

        def self.where_ngrok
          cmd = 'ngrok'
          exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
          ENV['PATH'].split(::File::PATH_SEPARATOR).each do |path|
            exts.each { |ext|
              exe = ::File.join(path, "#{cmd}#{ext}")
              return exe if ::File.executable?(exe) && !File.directory?(exe)
            }
          end
          return ::File.expand_path('~/bin/ngrok') if ::File.executable?(::File.expand_path('~/bin/ngrok'))
          return VagrantPlugins::Foodshow::Config::UNSET_VALUE
        end

        def self.build_cmd(config)
          cmd  = config.delete(:ngrok_bin)
          host = config.delete(:host)
          port = config.delete(:port)
          proto = config.delete(:proto)

          case proto
          when 'http'
            config['bind-tls'] = 'false'
          when 'https'
            config['bind-tls'] = 'true'
            proto = 'http'
          when 'http+https', 'https+http'
            proto = 'http'
          end

          cmd = cmd + ' ' + proto + ' -log=stdout'

          config.each_pair do |opt, val|
            cmd = cmd + " -" + opt.to_s + "=" + val.to_s
          end

          cmd = cmd + " " + host + ":" + port.to_s
        end

        def self.get_machine_id(env)
          if env[:machine].provider_name.to_s().start_with?('vmware')
            machine_id = env[:machine].id.match(/\h+\-\h+\-\h+\-\h+\-\h+/)[0]
          else
            machine_id = env[:machine].id
          end
        end

        def self.merge_config(env, tunnel)
          config = {}
          foodshow_config = env[:machine].config.foodshow

          config[:trust_host_root_certs] = foodshow_config.trust_host_root_certs if foodshow_config.trust_host_root_certs
          config[:server_addr]           = foodshow_config.server_addr           if foodshow_config.server_addr

          config[:ngrok_bin]     = foodshow_config.ngrok_bin     if foodshow_config.ngrok_bin
          config[:timeout]       = foodshow_config.timeout       if foodshow_config.timeout

          config[:authtoken]     = foodshow_config.authtoken     if foodshow_config.authtoken
          config[:hostname]      = foodshow_config.hostname      if foodshow_config.hostname
          config[:auth]          = foodshow_config.auth          if foodshow_config.auth
          config[:subdomain]     = foodshow_config.subdomain     if foodshow_config.subdomain
          config[:web_addr]      = foodshow_config.web_addr      if foodshow_config.web_addr
          config[:web_pbase]     = foodshow_config.web_pbase     if foodshow_config.web_pbase

          tunnel.keys.each do |key|
            raise unless NGROK_ALLOWED_OPTIONS.include? key.to_s
          end
          config.merge!(tunnel)

          machine_id = get_machine_id(env)

          config[:config]   = (env[:tmp_path] || "/tmp") + ("ngrok-" + machine_id + "-" + config[:port].to_s + ".cfg")
          config[:log_file] = (env[:tmp_path] || "/tmp") + ("ngrok-" + machine_id + "-" + config[:port].to_s + ".log")
          config[:pid_file] = (env[:tmp_path] || "/tmp") + ("ngrok-" + machine_id + "-" + config[:port].to_s + ".pid")
          config
        end
      end
    end
  end
end
