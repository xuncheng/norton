module Norton
  module Timestamp
    extend ActiveSupport::Concern

    included do
      include Norton::Helper
    end

    module ClassMethods
      #
      # [timestamp Define a timestamp]
      # @param name [type] [description]
      # @param touches={} [type] [description]
      #
      # @return [type] [description]
      def timestamp(name, options={})
        define_method(name) do
          ts = nil

          Norton.redis.with do |conn|
            ts = conn.get(self.norton_redis_key(name)).try(:to_i)

            if !options[:allow_nil] && ts.nil?
              ts = Time.now.to_i
              conn.set(self.norton_redis_key(name), ts)
            end

            ts
          end
        end

        define_method("touch_#{name}") do
          Norton.redis.with do |conn|
            if options[:digits].present? && options[:digits] == 13
              conn.set(self.norton_redis_key(name), (Time.now.to_f * 1000).to_i)
            else
              conn.set(self.norton_redis_key(name), Time.now.to_i)
            end
          end
        end

        define_method("remove_#{name}") do
          Norton.redis.with do |conn|
            conn.del("#{self.class.to_s.pluralize.underscore}:#{self.id}:#{name}")
          end
        end
        send(:after_destroy, "remove_#{name}".to_sym) if respond_to? :after_destroy

        # Add callback
        if options[:touch_on].present?
          options[:touch_on].each do |callback, condition|
            self.send callback, proc{ if instance_eval(&condition) then instance_eval("touch_#{name}") end }
          end
        end
      end
    end
  end
end
