require "vagrant-foodshow/action/start.rb"
require "vagrant-foodshow/action/stop.rb"
require "vagrant-foodshow/util/ngrok.rb"

module VagrantPlugins
  module Foodshow
    class Plugin < Vagrant.plugin("2")
      name "foodshow"
      config 'foodshow' do
        require_relative "config"
        Config
      end
      action_hook :ngrok_start_handler, :machine_action_up do |hook|
        hook.append(Action::Start)
      end

      action_hook :ngrok_start_handler, :machine_action_halt do |hook|
        hook.prepend(Action::Stop)
      end

      action_hook :ngrok_start_handler, :machine_action_reload do |hook|
        hook.prepend(Action::Stop)
        hook.append(Action::Start)
      end

      action_hook :ngrok_start_handler, :machine_action_suspend do |hook|
        hook.prepend(Action::Stop)
      end

      action_hook :ngrok_start_handler, :machine_action_resume do |hook|
        hook.append(Action::Start)
      end

    end
  end
end
