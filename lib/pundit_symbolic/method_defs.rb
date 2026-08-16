# typed: true
# frozen_string_literal: true

require "prism"

module PunditSymbolic
  # Extracts a policy class's instance-method defs as name(Symbol) ->
  # { node:, public: }, tracking `private` visibility and dropping Pundit's
  # field-authz methods (which return an attribute list, not a boolean — a
  # different surface the tool neither encodes nor flags).
  class MethodDefs
    FIELD_AUTHZ = %i[
      permitted_attributes permitted_attributes_for_create permitted_attributes_for_update
    ].freeze

    def self.extract(class_node)
      new(class_node).defs
    end

    attr_reader :defs

    def initialize(class_node)
      @defs = {}
      # Fold the class body, carrying visibility (a bare `private` flips it) and
      # recording each def under the visibility in effect at that point.
      class_node.body.body.reduce(:public) { |visibility, node| visit(node, visibility) }
    end

    private

    def visit(node, visibility)
      visibility = :private if private_marker?(node)
      record(node, visibility) if node.is_a?(Prism::DefNode)
      visibility
    end

    def record(node, visibility)
      name = node.name
      defs[name] = { node: node, public: visibility == :public } unless FIELD_AUTHZ.include?(name)
    end

    def private_marker?(node)
      node.is_a?(Prism::CallNode) && node.name == :private && node.arguments.nil?
    end
  end
end
