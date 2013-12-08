module WeiBackend
  class MessageDispatcher
    attr_accessor :params

    def on request_body
      @params = parse_params request_body
      msg_type = params[:MsgType]
      send(:"handle_#{msg_type}_message")
    end

    def self.on_text &block
      define_method(:handle_text_message, &block)
    end

    def self.on_event &block
      define_method(:handle_event_message, &block)
    end

    def self.on_voice &block
      define_method(:handle_voice_message, &block)
    end

    def parse_params(request_body)
      doc = Nokogiri::XML::Document.parse request_body
      result = {}
      doc.at_css('xml').element_children.each do |child|
        result[child.name.to_sym] = child.child.text
      end
      result
    end
  end

  module Delegator
    def self.delegate(*methods)
      methods.each do |method_name|
        define_method(method_name) do |*args, &block|
          Delegator.target.send(method_name, *args, &block)
        end
        private method_name
      end
    end

    delegate :on_text, :on_event, :on_voice

    class << self
      attr_accessor :target
    end

    self.target = MessageDispatcher
  end
end