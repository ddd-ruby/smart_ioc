# Extend Object with bean declaration and bean injection functionality
# Example of usage:
# class Bar
#   bean :bar
# end
#
# class Foo
#   include SmartIoC::Iocify
#   bean :foo, scope: :prototype, instance: false, factory_method: :get_beans
#
#   inject :bar
#   inject :some_bar, ref: bar, from: :repository
#
#   def hello_world
#     puts 'Hello world'
#   end
# end
#
# SmartIoC::Container.get_bean(:bar).hello_world
module SmartIoC::Iocify
  def self.included base
    base.extend ClassMethods
  end

  module ClassMethods
    # @param bean_name [Symbol] bean name
    # @param scope [Symbol] bean scope (defaults to :singleton)
    # @param package [nil or Symbol]
    # @param factory_method [nil or Symbol] factory method to get bean
    # @param instance [Boolean] instance based bean or class-based
    # @param context [Symbol] set bean context (ex: :test)
    # @return nil
    def bean(bean_name, scope: nil, package: nil, instance: true, factory_method: nil, context: nil)
      file_path = caller[0].split(':').first

      bean_definition = SmartIoC.get_bean_definition_by_class(self)

      if bean_definition
        if bean_definition.path == file_path
          # seems that file with bean definition was reloaded
          # lets clear all scopes so we do not have
          container = SmartIoC::Container.get_instance
          container.unregister_bean(self)
          container.force_clear_scopes
        else
          raise ArgumentError, "bean with for class #{self.to_s} was already defined in #{bean_definition.path}"
        end
      end

      bean_definition = SmartIoC.register_bean(
        bean_name:      bean_name,
        klass:          self,
        scope:          scope,
        path:           file_path,
        package_name:   package,
        instance:       instance,
        factory_method: factory_method,
        context:        context
      )

      if bean_definition.is_instance?
        class_eval %Q(
          def initialize
            raise ArgumentError, "constructor based allocation is not allowed for beans. Use ioc container to allocate bean."
          end
        )
      end

      nil
    end

    # @param bean_name [Symbol] injected bean name
    # @param ref [Symbol] refferece bean to be sef as bean_name
    # @param from [Symbol] package name
    # @return nil
    # @raise [ArgumentError] if bean_name is not a Symbol
    # @raise [ArgumentError] if ref provided and ref is not a Symbol
    # @raise [ArgumentError] if from provided and from is not a Symbol
    # @raise [ArgumentError] if bean with same name was injected before
    def inject(bean_name, ref: nil, from: nil)
      bean_definition = SmartIoC::Container.get_instance.get_bean_definition_by_class(self)

      if bean_definition.nil?
        raise ArgumentError, "#{self.to_s} is not registered as bean. Add `bean :bean_name` declaration"
      end

      bean_definition.add_dependency(
        bean_name: bean_name,
        ref:       ref,
        package:   from
      )

      if bean_definition.is_instance?
        class_eval %Q(
          private
            attr_reader :#{bean_name}
        )
      else
        class_eval %Q(
          class << self
            private
              attr_reader :#{bean_name}
          end
        )
      end

      nil
    end
  end
end
