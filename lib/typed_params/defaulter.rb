# frozen_string_literal: true

require 'typed_params/mapper'

module TypedParams
  class Defaulter < Mapper
    def call(params)
      return if params.nil?

      apply(params)

      params
    end

    private

    # Preorder walk: parents are materialized before their children,
    # so nested defaults apply inside a defaulted parent hash.
    def apply(param)
      case param.schema.children
      when Hash
        apply_hash(param)
      when Array
        apply_array(param)
      end
    end

    def apply_hash(param)
      return unless
        param.hash?

      param.schema.children.each do |key, child_schema|
        next if param.key?(key)
        next unless child_schema.default?
        next if guarded_out?(child_schema)

        param[key] = Parameterizer.new(schema: child_schema, parent: param).call(
          key: child_schema.key,
          value: evaluate(child_schema),
        )
      end

      param.schema.children.each do |key, _|
        child = param[key]
        apply(child) if child.is_a?(Parameter)
      end
    end

    def apply_array(param)
      return unless
        param.array?

      children = param.schema.children

      if param.schema.indexed?
        children.each_with_index do |child_schema, i|
          if i < param.value.size
            apply(param[i])
          elsif child_schema.default? && !guarded_out?(child_schema)
            param << Parameterizer.new(schema: child_schema, parent: param).call(
              key: child_schema.key,
              value: evaluate(child_schema),
            )
          end
        end
      else
        param.value.each { apply(_1) }
      end
    end

    def evaluate(child_schema)
      value = child_schema.default

      value = value.call if
        value.respond_to?(:call)

      case value
      when Array, Hash, String
        value.dup
      else
        value
      end
    end

    # Mirrors Bouncer's guard evaluation so guarded-out params
    # are not resurrected with defaults.
    def guarded_out?(child_schema)
      return false unless
        child_schema.if? || child_schema.unless?

      cond = child_schema.if? ? child_schema.if : child_schema.unless
      res  = case cond
             in Proc => method
               controller.instance_exec(&method)
             in Symbol => method
               controller.send(method)
             else
               raise InvalidMethodError, "invalid method: #{cond.inspect}"
             end

      kept = (child_schema.unless? && !res ||
        child_schema.if? && res)

      !kept
    end
  end
end
