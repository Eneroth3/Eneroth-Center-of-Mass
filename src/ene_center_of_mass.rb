require "extensions.rb"

# Eneroth Extensions
module Eneroth

# Eneroth Center of Mass
module CenterOfMass

  path = __FILE__
  path.force_encoding("UTF-8") if path.respond_to?(:force_encoding)

  PLUGIN_ID = File.basename(path, ".*")
  PLUGIN_DIR = File.join(File.dirname(path), PLUGIN_ID)

  EXTENSION = SketchupExtension.new(
    "Eneroth Center of Mass",
    File.join(PLUGIN_DIR, "main")
  )
  EXTENSION.creator     = "Eneroth3"
  EXTENSION.description =
    "Find center of mass for selection."
  EXTENSION.version     = "1.0.0"
  EXTENSION.copyright   = "2019, #{EXTENSION.creator}"
  Sketchup.register_extension(EXTENSION, true)

end
end
