module VagrantPlugins
  module Foodshow
    module Action
      class Start
        def initialize(app,env)
          @app = app
        end

        def call(env)
          @app.call(env)

          return unless env[:machine].config.foodshow.enabled?
          env[:machine].config.vm.networks.each do |network|
            if network[0] == :forwarded_port
              if network[1][:ngrok_proto] or (network[1][:id] == "ssh" && env[:machine].config.foodshow.forward_ssh?)

                if network[1][:id] == "ssh"
                  network[1][:ngrok_proto] = "tcp"
                end

                if network[1][:protocol] != "tcp"
                  env[:ui].error "Can't tunnel port #{network[1][:host]}, only tcp protocol supported. Skipping."
                  next
                end

                env[:machine].config.foodshow.tunnel(
                                                     network[1][:host],
                                                     network[1][:ngrok_proto],
                                                     :host  => network[1][:host_ip] || "127.0.0.1",
                                                    )
              end
            end
          end
          env[:machine].config.foodshow.tunnels.each do |tunnel|
            status, message, debug_output = VagrantPlugins::Foodshow::Util::Ngrok.start(env, tunnel)

            if status == 0
              env[:ui].success "Tunnel from " + message + " to " + tunnel[:host] + ":" + tunnel[:port].to_s
            elsif status == 1
              env[:ui].error "Ngrok failed: " + message
            elsif status == -1
              env[:ui].error message
              env[:ui].error "Ngrok output: " + debug_output.join()
            end
          end
        end
      end
    end
  end
end
