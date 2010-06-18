module Udev
  class Controller
    ENV_ACTION = 'ACTION'.freeze
    ENV_DEVTYPE = 'DEVTYPE'.freeze
    ENV_SUBSYSTEM = 'SUBSYSTEM'.freeze
    ENV_DEVNAME = 'DEVNAME'.freeze
    ENV_DEVPATH = 'DEVPATH'.freeze

    attr_reader :env

    def initialize(env)
      @env = env
    end

    def action; @env[ENV_ACTION]; end
    def on_action(action, &block)
      yield if self.action == action
    end

    def devtype; @env[ENV_DEVTYPE]; end
    def on_devtype(devtype, &block)
      yield if self.devtype == devtype
    end

    def subsystem; @env[ENV_SUBSYSTEM]; end
    def on_subsystem(subsystem, &block)
      yield if self.subsystem == subsystem
    end

    def devname; @env[ENV_DEVNAME]; end
    def ttyname; File.basename(devname); end

    def devpath(n = nil)
      if n.nil?
        @env[ENV_DEVPATH]
      else
        @env[ENV_DEVPATH].split('/')[n * -1, n].join('/')
      end
    end

    def parentpath(n = nil)
      if n.nil?
        devpath
      else
        paths = devpath.split('/')
        if paths.size > n
        paths[0, paths.size - n].join('/')
        else
          ""
        end
      end
    end

    def debug_info(l)
      @env.keys.each do |k|
        l.info { "#{k} = #{@env[k]}" }
      end
    end
  end
end
