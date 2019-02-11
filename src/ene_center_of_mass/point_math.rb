module Eneroth
  module CenterOfMass
    module PointMath
      refine Geom::Point3d do
        def *(factor)
          raise ArgumentError unless factor.is_a?(Numeric)
          Geom::Point3d.new(to_a.map { |c| c * factor } )
        end

        def +(point)
          Geom::Point3d.new(x + point.x, y + point.y, z + point.z)
        end

        def /(denominator)
          raise ArgumentError unless denominator.is_a?(Numeric)
          Geom::Point3d.new(to_a.map { |c| c / denominator } )
        end
      end
    end
  end
end
