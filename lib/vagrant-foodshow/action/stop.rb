module VagrantPlugins
  module Foodshow
    module Action
      class Stop
        def initialize(app, env)
          @app = app
        end

        def call(env)

          machine_id = VagrantPlugins::Foodshow::Util::NgrokConfig.get_machine_id(env)
          Dir.glob("#{env[:tmp_path] || '/tmp'}/ngrok-#{machine_id}-*.pid") do |pid_file|
            ::File.open(pid_file, 'r') do |f|
              begin
                pid = f.readline().to_i
                ::Process.kill('TERM', pid)
                ::File.delete(pid_file)
              rescue Errno::ESRCH
                ::File.delete(pid_file)
              ensure
                env[:ui].info('ngrok terminated')
              end
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
