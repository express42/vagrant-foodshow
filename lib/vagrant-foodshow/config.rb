module VagrantPlugins
  module Foodshow
    class Config < Vagrant.plugin(2, :config)

      attr_accessor :server_addr
      attr_accessor :trust_host_root_certs

      attr_accessor :timeout
      attr_accessor :enabled
      attr_accessor :forward_ssh

      attr_accessor :authtoken
      attr_accessor :hostname
      attr_accessor :auth
      attr_accessor :subdomain
      attr_accessor :web_addr
      attr_accessor :web_pbase

      attr_reader   :tunnels
      attr_reader   :ngrok_bin

      def initialize
        @forward_ssh  = UNSET_VALUE
        @enabled      = UNSET_VALUE
        @timeout      = UNSET_VALUE
        @ngrok_bin    = UNSET_VALUE
        @web_addr     = UNSET_VALUE
        @web_port     = UNSET_VALUE
        @tunnels      = []

        #ngrok params
        @authtoken    = UNSET_VALUE
        @hostname     = UNSET_VALUE
        @auth         = UNSET_VALUE
        @subdomain    = UNSET_VALUE

        # Options for self-hosted ngrokd
        @server_addr           = UNSET_VALUE
        @trust_host_root_certs = UNSET_VALUE
      end

      def tunnel(port, proto = "http+https", options={})
        host_hash = {:host => options[:host] || "127.0.0.1"}
        @tunnels << options.merge(:port => port).merge(:proto => proto).merge(host_hash)
      end

      def forward_ssh?
        @forward_ssh
      end

      def enabled?
        @enabled
      end

      def ngrok_bin=(path)
        @ngrok_bin = ::File.expand_path(path)
      end

      def validate(machine)
        errors = _detected_errors
        if @ngrok_bin == UNSET_VALUE
          errors << "Ngrok binary not found!\n"\
                    "  Make sure you have downloaded ngrok binary from http://ngrok.com\n"\
                    "  You can do this:\n"\
                    "  1) Add directory with ngrok binary your PATH\n"\
                    "  2) Add ngrok binary in ~/bin/ngrok\n"\
                    "  3) Set ngrok binary location with option foodshow.ngrok_bin in your vagrant file\n\n"\
                    "  You can read docs at http://github.com/express42/vagrant-foodshow"
        end

        unless @authtoken || @server_addr
          if @subdomain || @forward_ssh || @hostname
            errors << "You should set authtoken if you use subdomain/forward_ssh/hostname options"
          end
          
          @tunnels.each do |tunnel|

            unless tunnel[:authtoken]
              if tunnel[:hostname] || tunnel[:subdomain] || tunnel[:proto] == "tcp"
                errors << "You should set authtoken if you call foodshow.tunnel with subdomain/hostname/proto=tcp options"
              end
            end
          end

        end
        
        { "foodshow" => errors }
      end

      def finalize!
        @ngrok_bin = VagrantPlugins::Foodshow::Util::NgrokConfig.where_ngrok if @ngrok_bin == UNSET_VALUE

        @trust_host_root_certs = nil if @trust_host_root_certs == UNSET_VALUE
        @server_addr           = nil if @server_addr           == UNSET_VALUE

        @enabled       = false            if @enabled      == UNSET_VALUE
        @forward_ssh   = false            if @forward_ssh  == UNSET_VALUE
        @timeout       = 10               if @timeout      == UNSET_VALUE
        @authtoken     = nil              if @authtoken    == UNSET_VALUE
        @hostname      = nil              if @hostname     == UNSET_VALUE
        @auth          = nil              if @auth         == UNSET_VALUE
        @subdomain     = nil              if @subdomain    == UNSET_VALUE
        @web_addr      = "127.0.0.1"      if @web_addr     == UNSET_VALUE
        @web_pbase     = 4040             if @web_port     == UNSET_VALUE
      end
    end
  end
end
