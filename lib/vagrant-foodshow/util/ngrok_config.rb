module VagrantPlugins
  module Foodshow
    module Util
      class NgrokConfig
        NGROK_ALLOWED_OPTIONS = %w(authtoken hostname httpauth proto subdomain host port)

        def self.build_cmd(config)
          cmd  = config.delete(:ngrok_bin) + " -log=stdout"
          host = config.delete(:host)
          port = config.delete(:port)

          config.each_pair do |opt, val|
            cmd = cmd + " -" + opt.to_s + "=" + val.to_s
          end

          cmd = cmd + " " + host + ":" + port.to_s
        end

        def self.merge_config(env, tunnel)
          config = {}
          foodshow_config = env[:machine].config.foodshow

          config[:ngrok_bin]     = foodshow_config.ngrok_bin     if foodshow_config.ngrok_bin
          config[:timeout]       = foodshow_config.timeout       if foodshow_config.timeout

          config[:authtoken]     = foodshow_config.authtoken     if foodshow_config.authtoken
          config[:hostname]      = foodshow_config.hostname      if foodshow_config.hostname
          config[:httpauth]      = foodshow_config.httpauth      if foodshow_config.httpauth
          config[:subdomain]     = foodshow_config.subdomain     if foodshow_config.subdomain
          config[:inspect_addr]  = foodshow_config.inspect_addr  if foodshow_config.inspect_addr
          config[:inspect_pbase] = foodshow_config.inspect_pbase if foodshow_config.inspect_pbase

          tunnel.keys.each do |key|
            raise unless NGROK_ALLOWED_OPTIONS.include? key.to_s
          end
          config.merge!(tunnel)

          if env[:machine].provider_name.to_s().start_with?('vmware')
            machine_id = env[:machine].id.match(/\h+\-\h+\-\h+\-\h+\-\h+/)[0]
          else
            machine_id = env[:machine].id
          end

          config[:config]   = (env[:tmp_path] || "/tmp") + ("ngrok-" + machine_id + "-" + config[:port].to_s + ".cfg")
          config[:log_file] = (env[:tmp_path] || "/tmp") + ("ngrok-" + machine_id + "-" + config[:port].to_s + ".log")
          config[:pid_file] = (env[:tmp_path] || "/tmp") + ("ngrok-" + machine_id + "-" + config[:port].to_s + ".pid")
          config
        end
      end
    end
  end
end
