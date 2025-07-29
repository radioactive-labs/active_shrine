require "test_helper"
require "generators/active_shrine/install/install_generator"

class GeneratorTest < Minitest::Test
  def setup
    @generator = ActiveShrine::InstallGenerator
    @destination_root = File.expand_path("test_generator_files", __dir__)
  end

  def teardown
    FileUtils.rm_rf(@destination_root) if File.exist?(@destination_root)
  end

  def test_generates_files
    @generator.start [], destination_root: @destination_root, behavior: :invoke

    # Check config files
    assert File.exist?(File.join(@destination_root, "config/initializers/shrine.rb"))

    # Check job files
    assert File.exist?(File.join(@destination_root, "app/jobs/destroy_shrine_attachment_job.rb"))
    assert File.exist?(File.join(@destination_root, "app/jobs/promote_shrine_attachment_job.rb"))

    # Check migration
    migration_file = Dir.glob(File.join(@destination_root, "db/migrate/*_create_active_shrine_attachments.rb")).first
    assert migration_file, "Migration file was not generated"
    assert_match(/create_table :active_shrine_attachments/, File.read(migration_file))
  end
end
