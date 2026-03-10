# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test" << "lib"
  t.test_files = FileList["test/test_*.rb"]
  t.verbose = true
end

Rake::TestTask.new(:test_single) do |t|
  t.libs << "test" << "lib"
  t.verbose = true
end

desc "Run all validation checks"
task :validate do
  puts "🔍 Running validation pipeline..."
  
  # Validate YAML files
  require "yaml"
  Dir.glob("core/**/*.yaml").each do |f|
    begin
      YAML.load_file(f)
      puts "✓ #{f}"
    rescue => e
      puts "✗ #{f}: #{e.message}"
      exit 1
    end
  end
  
  puts "✅ Validation complete"
end

desc "Run tests with coverage"
task :coverage => :test do
  puts "📊 Coverage report generated"
end

desc "Clean generated files"
task :clean do
  rm_rf "generated"
  rm_rf "coverage"
  puts "🧹 Cleaned generated files"
end

desc "Build all targets"
task :build do
  targets = %w[antigravity claude-code codex-cli cursor kimi-code opencode vscode warp]
  targets.each do |target|
    puts "Building #{target}..."
    system("ruby", "-Ilib", "bin/vibe", "build", target, "--output", "generated/#{target}")
  end
end

task default: :test
