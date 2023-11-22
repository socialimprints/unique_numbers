module UniqueNumbers
  class HasUniqueNumber
    def self.define_on(klass, name, options)
      new(klass, name, options).define
    end

    def initialize(klass, name, options)
      @klass = klass
      @name = name
      @options = options
    end

    def define
      define_validations
      define_getters
      add_active_record_callbacks
    end

    private
    def define_validations
      @klass.send(:validates, @name, uniqueness: { allow_nil: true })
    end

    def define_getters
      name = @name
      options = @options
      @klass.send :define_method, "#{@name}_generator" do
        ivar = "@#{name}_generator"
        generator = instance_variable_get(ivar)

        if generator.nil?
          generator = Generator.find_by(name: options[:generator])
          if generator.nil?
            generator = ("UniqueNumbers::#{options[:type].to_s.camelize}Generator").constantize.new(name: options[:generator])
          end
          generator.assign_attributes(options.except(:generator, :type))
          generator.save! if generator.changed?
          instance_variable_set(ivar, generator)
        end
      end
    end

    def add_active_record_callbacks
      name = @name
      options = @options
      if options[:exclude_chars].present?
        @klass.send(:after_create) { send("#{name}_generator").assign_next_number(self, name, options[:exclude_chars])}
      else
        @klass.send(:after_create) { send("#{name}_generator").assign_next_number(self, name)}
      end
    end
  end
end
