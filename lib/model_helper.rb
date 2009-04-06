module ModelHelper
  def self.current_controller
    @current_controller
  end
  
  def self.current_controller=(value)
    @current_controller = value
  end
  
  def self.delegate_to_controller(*args)
    @current_controller and @current_controller.send(*args)
  end
  
  def self.add_hooks(target)
    if (target.respond_to?(:before_filter) and !@before_filter_controller_hook)
      @before_filter_controller_hook = Proc.new { |controller|
        @current_controller = controller
      }

      target.send(:before_filter, @before_filter_controller_hook)
    end
  end
  
  module ControllerClassMethods
    def model_method(name, default_target = nil, options = { })
      if (default_target)
        ModelHelper.current_controller = default_target
      end
      
      ModelHelper.add_hooks(self)
      
      get_message = name.to_sym
      set_message = "#{name}=".to_sym
      
      model_methods = Module.new
      
      model_methods.send(:define_method, get_message) do
        ModelHelper.delegate_to_controller(get_message)
      end

      model_methods.send(:define_method, set_message) do |value|
        ModelHelper.delegate_to_controller(set_message, value)
      end
      
      [ :include, :extend ].each do |message|
        ActiveRecord::Base.send(message, model_methods)
      end
    end
  end
end
