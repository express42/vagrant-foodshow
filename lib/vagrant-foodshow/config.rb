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
      attr_accessor :httpauth
      attr_accessor :subdomain
      attr_accessor :inspect_addr
      attr_accessor :inspect_pbase

      attr_reader   :tunnels
      attr_reader   :ngrok_bin

      def initialize
        @forward_ssh  = UNSET_VALUE
        @enabled      = UNSET_VALUE
        @timeout      = UNSET_VALUE
        @ngrok_bin    = UNSET_VALUE
        @inspect_addr = UNSET_VALUE
        @inspect_port = UNSET_VALUE
        @tunnels      = []

        #ngrok params
        @authtoken    = UNSET_VALUE
        @hostname     = UNSET_VALUE
        @httpauth     = UNSET_VALUE
        @subdomain    = UNSET_VALUE

        # Options for self-hosted ngrokd
        @server_addr           = UNSET_VALUE
        @trust_host_root_certs = UNSET_VALUE
      end

      def tunnel(port, proto = "http+https", options={})
        host_hash = {:host => options[:host] || "127.0.0.1"}
        @tunnels << options.merge(:port => port).merge( :proto => proto).merge(host_hash)
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
        unless ::File.executable? @ngrok_bin
          errors << "You must put ngrok binary to #{@ngrok_bin}.\n"\
                    "  Go to http://ngrok.com and download ngrok binary.\n"\
                    "  You can change binary location by changing option foodshow.ngrok_bin.\n\n"\
                    "  EXAMPLE. Download and unpack ngrok to ~/bin on Mac OS x86_64:\n"\
                    "  curl -O https://dl.ngrok.com/darwin_amd64/ngrok.zip && unzip ngrok.zip && mkdir -p ~/bin && mv ngrok ~/bin\n\n"\
                    "  You can read docs at http://github.com/express42/vagrant-foodshow\n"
        end

        unless @authtoken
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
        @ngrok_bin = ::File.expand_path('~/bin/ngrok') if @ngrok_bin == UNSET_VALUE

        @trust_host_root_certs = nil if @trust_host_root_certs == UNSET_VALUE
        @server_addr           = nil if @server_addr           == UNSET_VALUE

        @enabled       = false            if @enabled      == UNSET_VALUE
        @forward_ssh   = false            if @forward_ssh  == UNSET_VALUE
        @timeout       = 10               if @timeout      == UNSET_VALUE
        @authtoken     = nil              if @authtoken    == UNSET_VALUE
        @hostname      = nil              if @hostname     == UNSET_VALUE
        @httpauth      = nil              if @httpauth     == UNSET_VALUE
        @subdomain     = nil              if @subdomain    == UNSET_VALUE
        @inspect_addr  = "127.0.0.1"      if @inspect_addr == UNSET_VALUE
        @inspect_pbase = 4040             if @inspect_port == UNSET_VALUE
      end
    end
  end
end
