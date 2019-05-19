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
      # @return [Numeric]
      def self.from_path(path)
        path.reverse.lazy.map { |e| e.get_attribute(ATTR_DICT, "density") }
                         .detect(&:itself) || DEFAULT
      end
    end
  end
end
