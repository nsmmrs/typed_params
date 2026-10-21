# frozen_string_literal: true

module TypedParams
  class Configuration
    ##
    # ignore_nil_optionals defines how nil optionals are handled.
    # When enabled, optional params that are nil will be dropped
    # given the schema does not allow_nil. Essentially, they
    # will be treated as if they weren't provided.
    class_attribute :ignore_nil_optionals
    self.ignore_nil_optionals = false

    ##
    # path_transform defines the casing for parameter paths.
    #
    # One of:
    #
    #   - :underscore
    #   - :camel
    #   - :lower_camel
    #   - :dash
    #   - nil
    #
    class_attribute :path_transform
    self.path_transform = nil

    ##
    # key_transform defines the casing for parameter keys.
    #
    # One of:
    #
    #   - :underscore
    #   - :camel
    #   - :lower_camel
    #   - :dash
    #   - nil
    #
    class_attribute :key_transform
    self.key_transform = nil

    ##
    # filtered_params defines keys that are stripped from incoming
    # request parameters before parameterization. This is useful for
    # ignoring internal parameters injected by Rails form helpers,
    # such as `authenticity_token` and `_method`, which would otherwise
    # raise `UnpermittedParameterError` in strict schemas.
    #
    # Keys declared via `param` (or `:alias`) in the schema always win
    # and are never filtered.
    #
    class_attribute :filtered_params
    self.filtered_params = %i[authenticity_token _method]
  end
end
