require 'bundler'
require 'yaml'
require 'fileutils'

module Papers

  class FileExistsError < StandardError;
    attr_reader :manifest_path

    def initialize(path)
      @manifest_path = path
      super
    end
  end

  class ManifestGenerator

    def generate!(args = ARGV)
      @manifest_path = File.join('config','papers_manifest.yml')

      raise Papers::FileExistsError.new(@manifest_path) if manifest_exists?

      begin
        if FileUtils.mkdir_p(File.dirname(@manifest_path))
          File.open(@manifest_path, 'w') do |file|
            file.write(build_header)
            file.write(YAML.dump(build_manifest))
          end
          puts "Created #{@manifest_path}!"
        end
      rescue RuntimeError => e
        warn "Failure! #{e}"
      end
    end

    private

    def build_manifest
      manifest = {
        "gems"        => get_installed_gems,
        "javascripts" => get_installed_javascripts
      }
      return manifest
    end

    def get_installed_gems
      gems = {}
      Bundler.load.specs.each do |spec|
        if spec.name == 'bundler'
          name_and_version = spec.name
        else
          name_and_version = "#{spec.name}-#{spec.version}"
        end

        gems[name_and_version] = {
          'license'     => spec.license || 'Unknown',
          'license_url' => nil,
          'project_url' => spec.homepage || nil
          # TODO: add support for multiple licenses? some gemspecs have dual licensing
        }
      end
      return gems
    end

    def get_installed_javascripts
      js = {}
      Javascript.introspected.each do |entry|
        js[entry] = {
          'license'     => 'Unknown',
          'license_url' => nil,
          'project_url' => nil
        }
      end
      js.empty? ? nil : js
    end

    def manifest_exists?
      !!File.exist?(@manifest_path)
    end

    def build_header
      [
        "# Dependency Manifest for the Papers gem",
        "# Used to test your gems and javascript against license whitelist",
        "#",
        "# http://github.com/newrelic/papers\n"
      ].join("\n")
    end

  end

end