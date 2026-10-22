# frozen_string_literal: true

require 'typed_params/mapper'

module TypedParams
  class Bouncer < Mapper
    def call(params)
      depth_first_map(params) do |param|
        next if
          guard_passes?(param.schema)

        if param.schema.strict?
          raise UnpermittedParameterError.new('unpermitted parameter', path: param.path, source: schema.source)
        else
          param.delete
        end
      end
    end
  end
end
