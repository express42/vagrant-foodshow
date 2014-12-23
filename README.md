# Foodshow: Share your [Vagrant](http://vagrantup.com) virtual machine

[![Code Climate](https://codeclimate.com/github/express42/vagrant-foodshow.png)](https://codeclimate.com/github/express42/vagrant-foodshow) [![express42/vagrant-foodshow API Documentation](https://www.omniref.com/github/express42/vagrant-foodshow.png)](https://www.omniref.com/github/express42/vagrant-foodshow)

Vagrant-Foodshow plugin allows you to share tcp ports of your virtual machine via the Internet.

With this plugin you may show your web application to your colleague, present new feature for your customer and give ssh access to your ops guy.

All tunneling job performed by [Ngrok](http://ngrok.com) backend.
Ngrok tunnel can operate in TCP and HTTP modes. In HTTP tunnel mode `ngrok` provides access to HTTP requests and response from server to help you analyze the traffic. In TCP mode you can tunnel any binary protocol like `ssh`, `postgresql` or whatever you want, but there is no introspection in TCP tunnel.

## Vagrant-foodshow and vagrant-share

Vagrant-foodshow unlike vagrnat-share an opensource product. Ngrok client and server part is also opensource. Ngrok server and server-side part of vagrant-share both available as SAAS solutions, but you can setup your own ngrok server for free. This is a good solution if you don't want send tunneled traffic through third-party servers.

## Installation

### Ngrok installation

You should go to [ngrok.com](http://ngrok.com) and download ngrok binary for your system. Vagrant-foodshow will search ngrok binary in PATH. `~/bin/ngrok` will be used if no ngrok binary in PATH. To disable search you may set `foodshow.ngrok_bin` option (See [Advanced tunnel example](#advanced-tunnel-example)).

### Plugin installation

To install this plugin just execute:

```bash
vagrant plugin install vagrant-foodshow
```

## Usage&Configuration

First of all you should enable plugin in your `Vagrantfile`:
```ruby
config.foodshow.enabled = true
```

### There are two ways to create a tunnel

##### Call method `foodshow.tunnel` :

```ruby
...
config.foodshow.tunnel <host_port>, <protocol>, [options hash]
...
```

##### Add `ngrok_proto` parameter to `vm.network` :

```ruby
...
config.vm.network :forwarded_port, guest: <guest_port>, host: <host_port>, ngrok_proto: "<protocol>"
...
```

Default tunnel protocol is `http+https`. Ngrok supports `http`, `https`, `http+https` and `tcp`. For tcp protocol authtoken is required.

### Simple tunnel example

```ruby
Vagrant.configure("2") do |config|
  #Enable foodshow
  config.foodshow.enabled = true
  ...
  # Define vm
  config.vm.define :web01 do |conf|
    ...
    #Just add ngrok_proto parameter to your port forwarding entry
    conf.vm.network :forwarded_port, guest: 80, host: 8080, ngrok_proto: "http+https"
    ...
    end
end
```

### Advanced tunnel example

```ruby
Vagrant.configure("2") do |config|
  #Enable foodshow
  config.foodshow.enabled = true
  # Change ngrok binary location
  config.foodshow.ngrok_bin = "/usr/local/bin/ngrok"
  # Automaticly search ssh port and create tcp tunnel
  config.foodshow.forward_ssh = true
  ...
  # Define vms
  config.vm.define :web01 do |conf|
    ...
    conf.vm.network :forwarded_port, guest: 80, host: 8080, ngrok_proto: "http+https"
    # Don't tunnel ssh for this vm
    config.foodshow.forward_ssh = false
    # For this vm we use another token
    conf.foodshow.authtoken = <sometoken_2>
    ...
  end
  config.vm.define :web02 do |conf|
    ...
    conf.vm.network :forwarded_port, guest: 80, host: 8081
    conf.vm.network :forwarded_port, guest: 389, host: 3389
    # You may pass some params as tunnel options
    # This code creates a tunnel http://mycopmanyllc.ngrok.com with basic auth
    conf.foodshow.tunnel 8081, "http", :httpauth => "foodshow:ngrok" :subdomain => "mycopmanyllc"
    # And sure you may tunnel any tcp port
    conf.foodshow.tunnel 3389, "tcp"
    ...
  end
end
```

### Self-hosted tunnel example

```ruby
Vagrant.configure("2") do |config|
  #Enable foodshow
  config.foodshow.enabled = true
  # Set your ngrokd server
  config.foodshow.server_addr = "127.0.0.1:4443"
  # Allow host root certificate
  config.foodshow.trust_host_root_certs = true
  ...
  # Define vm
  config.vm.define :web01 do |conf|
    ...
    #Just add ngrok_proto parameter to your port forwarding entry
    conf.vm.network :forwarded_port, guest: 80, host: 8080, ngrok_proto: "http+https"
    ...
    end
end
```
Read this document if you want to start self-hosted server https://github.com/inconshreveable/ngrok/blob/master/docs/SELFHOSTING.md
### Options

- Scope *config* means that this option can be set only via `foodshow.<options>`
- Scope *config+tunnel* means that this option can be set via `foodshow.<options>` and can be can be passed to the `foodshow.tunnel` method as options hash.
- Scope *tunnel* means that this option can be passed to the `foodshow.tunnel` method

Option | Default | Scope | Purpose
-------|---------|---------|--------
`enabled` | `false` |  config | Enable foodshow plugin
`ngrok_bin` | `nil` | config+tunnel |  By default vagrant-foodshow will search ngrok binary in PATH, then at ~/bin/ngrok. You may override this behavior by setting this option
`forward_ssh` | `false` | config | Automatically search and forward vagrant ssh guest port (authtoken required)
`timeout` | `10` | config | Max waiting time for establishing tunnel
`authtoken` | `nil` | config+tunnel | Auth token. Required for TCP tunnels and some functions (Go to [ngrok.com](http://ngrok.com) to get authkey)
`httpauth` | `nil` | config+tunnel | You may set basic auth for http/https tunnel. Format: `user:password`
`subdomain` | `nil` | config+tunnel | Custom subdomain for http/https tunnel. URL will be like a http://\<subdomain\>.ngrok.com
`hostname` | `nil` | config+tunnel | Custom domain for http/https tunnel (Paid feature, see [Pricing & Features](http://ngrok.com/features) on ngrok website )
`host_ip` | `127.0.0.1` | tunnel | Custom destination ip for tunnel
`inspect_addr` | `127.0.0.1` | config | Address for traffic inspection
`inspect_pbase` | `4040` | config | Base port for traffic inspection, other ngrok  processes will use the next available port
`server_addr` | `nil` | config+tunnel | Server address for self-hosted ngrokd, see [Self-hosted tunnels example](#self-hosted-tunnel-example)
`trust_host_root_certs` | `nil` | config+tunnel | Allow ngrok accept root server certificate. Must be `true` if you using self-hosted ngrokd

# Authors

* Nikita Borzykh (<sample.n@gmail.com>)

## Contributing

1. Fork it ( http://github.com/express42/vagrant-foodshow/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
