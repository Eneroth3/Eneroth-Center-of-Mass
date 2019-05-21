module Eneroth
  module CenterOfMass
    # Read and write density information to the model.
    #
    # Density cascades through the model hierarchy similarly to material or
    # layer info.
    #
    # TODO: What unit? For now some kind of multiple of base unit "1".
    # Setter.
    # inherited?(path)
    module Density
      ATTR_DICT = PLUGIN_ID
      # TODO: Set reasonable default.
      DEFAULT = 1

      # Get density from entity path.
      #
      # @param path [Array<Sketchup::ComponentInstance, SketchUp::Group>]
      #   Path from root to leaf.
      #
      # @example
      #   model = Sketchup.active_model
      #   path = (model.active_path || []) + [model.selection.first]
      #   Eneroth::CenterOfMass::Density.from_path(path)
      #
      # @return [Numeric]
      def self.from_path(path)
        path.reverse.lazy.map { |e| e.get_attribute(ATTR_DICT, "density") }
                         .detect(&:itself) || DEFAULT
      end

      # Get object density is inherited from.
      #
      # @param path [Array<Sketchup::ComponentInstance, SketchUp::Group>]
      #   Path from root to leaf.
      #
      # @return [Sketchup::ComponentInstance, Sketchup::Group, Sketchup::Model,
      #   nil]
      def self.inherited_from(path)
        path.reverse.detect { |e| e.get_attribute(ATTR_DICT, "density") }
      end

      # Check if density is set locally for entity, as opposed to be inherited
      # from parent container.
      #
      # @param entity [Sketchup::ComponentInstance, SketchUp::Group,
      #   Sketchup::Model]
      #
      # @return [Boolean]
      def self.local_density?(entity)
        !!entity.get_attribute(ATTR_DICT, "density")
      end

      # Set density for entity.
      #
      # @param entity [Sketchup::ComponentInstance, SketchUp::Group,
      #   Sketchup::Model]
      # @param density [Numeric]
      #
      # @return [void]
      def self.set_density(entity, density)
        entity.set_attribute(ATTR_DICT, "density", desnity)
      end
    end
  end
end
