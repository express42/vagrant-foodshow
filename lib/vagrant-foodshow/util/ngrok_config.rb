require 'yaml'

module VagrantPlugins
  module Foodshow
    module Util
      class NgrokConfig
        NGROK_ALLOWED_OPTIONS = %w(authtoken hostname httpauth auth proto subdomain host port server_addr trust_host_root_certs)

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

        def self.ngrok_version
          return @ngrok_version unless @ngrok_version.nil?
          cmd = where_ngrok
          @ngrok_version = `#{cmd} version`.gsub!(/[^\d\.]/, '')
        end

        def self.ngrok_version_deprecated?
          ngrok_version < '2.'
        end

        def self.build_cmd(config)
          cmd = config.delete(:ngrok_bin)
          host = config.delete(:host)
          port = config.delete(:port)

          if ngrok_version_deprecated?
            cmd += ' -log=stdout'
          else
            proto = config.delete(:proto)
            case proto
              when 'http'
                config['bind-tls'] = 'false'
              when 'https'
                config['bind-tls'] = 'true'
                proto = 'http'
              when 'http+https', 'https+http'
                config['bind-tls'] = 'both'
                proto = 'http'
              else
                # ignored
            end
            cmd += ' ' + proto + ' -log=stdout -log-level=debug -log-format=json'
          end

          config.each_pair do |opt, val|
            cmd += ' -' + opt.to_s + '=' + val.to_s
          end

          cmd += ' ' + host + ':' + port.to_s
        end

        def self.get_machine_id(env)
          if env[:machine].provider_name.to_s.start_with?('vmware')
            machine_id = env[:machine].id.match(/\h+\-\h+\-\h+\-\h+\-\h+/)[0]
          else
            machine_id = env[:machine].id
          end
        end

        def self.merge_config(env, tunnel)
          config = {}
          foodshow_config = env[:machine].config.foodshow

          config[:trust_host_root_certs] = foodshow_config.trust_host_root_certs if foodshow_config.trust_host_root_certs
          config[:server_addr] = foodshow_config.server_addr if foodshow_config.server_addr

          config[:ngrok_bin] = foodshow_config.ngrok_bin if foodshow_config.ngrok_bin
          config[:timeout] = foodshow_config.timeout if foodshow_config.timeout

          config[:authtoken] = foodshow_config.authtoken if foodshow_config.authtoken
          config[:hostname] = foodshow_config.hostname if foodshow_config.hostname
          config[:subdomain] = foodshow_config.subdomain if foodshow_config.subdomain

          auth = foodshow_config.auth || foodshow_config.httpauth
          web_addr = foodshow_config.web_addr || foodshow_config.inspect_addr
          web_pbase = foodshow_config.web_pbase || foodshow_config.inspect_pbase

          if ngrok_version_deprecated?
            config[:httpauth] = auth
            config[:inspect_addr] = web_addr
            config[:inspect_pbase] = web_pbase
          else
            config[:auth] = auth
            config[:web_addr] = web_addr
            config[:web_pbase] = web_pbase
          end

          tunnel.keys.each do |key|
            raise unless NGROK_ALLOWED_OPTIONS.include? key.to_s
          end
          config.merge!(tunnel)

          machine_id = get_machine_id(env)

          config[:config] = (env[:tmp_path] || '/tmp') + ('ngrok-' + machine_id + '-' + config[:port].to_s + '.cfg')
          config[:log_file] = (env[:tmp_path] || '/tmp') + ('ngrok-' + machine_id + '-' + config[:port].to_s + '.log')
          config[:pid_file] = (env[:tmp_path] || '/tmp') + ('ngrok-' + machine_id + '-' + config[:port].to_s + '.pid')
          config
        end
      end
    end
  end
end
