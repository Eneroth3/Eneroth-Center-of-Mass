module Eneroth
  module CenterOfMass
    module PointMath
      refine Geom::Point3d do
        def *(other)
          raise ArgumentError unless other.is_a?(Numeric)
          Geom::Point3d.new(to_a.map { |c| c * other })
        end

        def +(other)
          Geom::Point3d.new(x + other.x, y + other.y, z + other.z)
        end

        def /(other)
          raise ArgumentError unless other.is_a?(Numeric)
          Geom::Point3d.new(to_a.map { |c| c / other })
        end
      end
    end
  end
end
