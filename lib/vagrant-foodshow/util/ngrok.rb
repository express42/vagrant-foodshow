require 'json'
require 'open3'
require 'timeout'
require 'vagrant-foodshow/util/ngrok_config.rb'
require 'vagrant/util/platform'

module VagrantPlugins
  module Foodshow
    module Util
      class Ngrok

        def initialize
        end

        def self.start(env, tunnel)
          @ngrok_version_deprecated = VagrantPlugins::Foodshow::Util::NgrokConfig.ngrok_version_deprecated?
          if defined?(@@counter)
            @@counter += 1
          else
            @@counter = 0
          end

          config = VagrantPlugins::Foodshow::Util::NgrokConfig.merge_config(env, tunnel)

          trust_host_root_certs = config.delete(:trust_host_root_certs)
          server_addr = config.delete(:server_addr)

          timeout = config.delete(:timeout)
          log_file = config.delete(:log_file)
          pid_file = config.delete(:pid_file)
          authtoken = config.delete(:authtoken)

          inspect_addr = config.delete(:inspect_addr)
          inspect_pbase = config.delete(:inspect_pbase)

          web_addr = config.delete(:web_addr)
          web_pbase = config.delete(:web_pbase)

          config_file = config[:config]

          cmd = VagrantPlugins::Foodshow::Util::NgrokConfig.build_cmd(config)

          begin
            current_pid = -1
            ::File.open(pid_file) { |pid| current_pid = pid.readline(); }
            Process.getpgid(current_pid.to_i)
            return 0, "Ngrok already running at pid #{current_pid}. Skipping tunnel", ''
          rescue
            # ignored
          end

          ::File.open(config_file, 'w') do |conf_h|

            if @ngrok_version_deprecated
              conf_h.write("inspect_addr: #{inspect_addr.to_s}:#{inspect_pbase.to_i + @@counter}\n")
            else
              conf_h.write("web_addr: #{web_addr.to_s}:#{web_pbase.to_i + @@counter}\n")
            end

            if server_addr
              conf_h.write("server_addr: #{server_addr}\n")
            end

            if trust_host_root_certs
              conf_h.write("trust_host_root_certs: true\n")
            end

            if authtoken
              if @ngrok_version_deprecated
                conf_h.write("auth_token: #{authtoken}\n")
              else
                conf_h.write("authtoken: #{authtoken}\n")
              end
            end

          end

          pid = spawn(cmd, :out => log_file.to_s)

          ::File.open(pid_file, 'w') { |pid_h| pid_h.write(pid) }

          log_h = ::File.open(log_file, 'r')
          status, message, debug_output = parse_log(log_h, timeout)
          log_h.close

          unless status == 0
            begin
              ::File.delete(pid_file)
              sigterm = Vagrant::Util::Platform.windows? ? 'KILL' : 'TERM'
              ::Process.kill(sigterm, pid)
            rescue
              # ignored
            end
          end

          return status, message, debug_output
        end

        private

        def self.parse_log(log_h, timeout)
          @ngrok_version_deprecated = VagrantPlugins::Foodshow::Util::NgrokConfig.ngrok_version_deprecated?
          debug_output = []
          begin
            timeout(timeout.to_i) do
              while true do
                begin
                  stdout_str = log_h.readline()
                rescue
                  next
                end
                debug_output << stdout_str
                if @ngrok_version_deprecated
                  if stdout_str.include? '[INFO] [client] Tunnel established at'
                    return 0, stdout_str[/(http\:\/\/|https\:\/\/|tcp\:\/\/).+/], debug_output
                  end
                  if stdout_str.include? '[EROR]'
                    if stdout_str.include? 'Error while checking for update'
                      next
                    else
                      return 1, stdout_str, debug_output
                    end
                  end
                else
                  stdout_json = JSON.parse(stdout_str)
                  if stdout_json.include?('err') && stdout_json['err'] != '<nil>'
                    return 1, stdout_json['err'], debug_output
                  end
                  if stdout_json.include?('msg') && stdout_json['msg'] == 'decoded response'
                    if stdout_json['resp'].match(/URL:/)
                      return 0, stdout_json['resp'][/\sURL:(.+?)\s/, 1], debug_output
                    end
                  end
                end
              end
            end
          rescue ::Timeout::Error
            return -1, 'Ngrok wait timeout. See ngrok output:', debug_output
          end
        end
      end
    end
  end
end
