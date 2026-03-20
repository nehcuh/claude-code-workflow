# frozen_string_literal: true

module Vibe
  # Detects the toolchain used in a project directory.
  # Returns structured info about package managers, build tools, and test frameworks.
  class ToolchainDetector
    # Each entry: { files: [], command: nil, lock_files: [] }
    PACKAGE_MANAGERS = {
      # Node.js
      bun:    { files: %w[bun.lockb], command: "bun",  ecosystem: "node" },
      pnpm:   { files: %w[pnpm-lock.yaml],             command: "pnpm", ecosystem: "node" },
      yarn:   { files: %w[yarn.lock],                  command: "yarn", ecosystem: "node" },
      npm:    { files: %w[package-lock.json],           command: "npm",  ecosystem: "node" },
      # Python
      poetry: { files: %w[poetry.lock pyproject.toml], command: "poetry", ecosystem: "python" },
      pipenv: { files: %w[Pipfile.lock Pipfile],        command: "pipenv", ecosystem: "python" },
      pip:    { files: %w[requirements.txt],            command: "pip",    ecosystem: "python" },
      # Rust
      cargo:  { files: %w[Cargo.lock Cargo.toml],       command: "cargo",  ecosystem: "rust" },
      # Go
      gomod:  { files: %w[go.mod],                      command: "go",     ecosystem: "go" },
      # Ruby
      bundler: { files: %w[Gemfile.lock Gemfile],        command: "bundle", ecosystem: "ruby" }
    }.freeze

    BUILD_TOOLS = {
      vite:    { files: %w[vite.config.ts vite.config.js],           ecosystem: "node" },
      webpack: { files: %w[webpack.config.js webpack.config.ts],     ecosystem: "node" },
      rollup:  { files: %w[rollup.config.js rollup.config.ts],       ecosystem: "node" },
      esbuild: { files: %w[esbuild.config.js],                       ecosystem: "node" },
      gradle:  { files: %w[build.gradle build.gradle.kts gradlew],   ecosystem: "jvm" },
      maven:   { files: %w[pom.xml],                                  ecosystem: "jvm" },
      cmake:   { files: %w[CMakeLists.txt],                           ecosystem: "cpp" },
      make:    { files: %w[Makefile GNUmakefile],                     ecosystem: "generic" },
      rake:    { files: %w[Rakefile],                                  ecosystem: "ruby" }
    }.freeze

    TEST_FRAMEWORKS = {
      vitest:  { files: %w[vitest.config.ts vitest.config.js],        ecosystem: "node" },
      jest:    { files: %w[jest.config.js jest.config.ts],            ecosystem: "node" },
      pytest:  { files: %w[pytest.ini pyproject.toml setup.cfg],      ecosystem: "python" },
      rspec:   { files: %w[.rspec spec/spec_helper.rb],               ecosystem: "ruby" },
      minitest: { files: %w[test/test_helper.rb],                     ecosystem: "ruby" },
      cargo_test: { files: %w[Cargo.toml],                            ecosystem: "rust" },
      go_test: { files: %w[go.mod],                                   ecosystem: "go" }
    }.freeze

    attr_reader :project_root

    def initialize(project_root = nil)
      @project_root = project_root || Dir.pwd
    end

    # Run full detection and return a structured result
    # @return [Hash]
    def detect
      {
        project_root: @project_root,
        ecosystems: detected_ecosystems,
        package_managers: detect_category(PACKAGE_MANAGERS),
        build_tools: detect_category(BUILD_TOOLS),
        test_frameworks: detect_category(TEST_FRAMEWORKS),
        primary_language: primary_language,
        suggested_commands: suggested_commands
      }
    end

    # Detect only package managers
    def detect_package_managers
      detect_category(PACKAGE_MANAGERS)
    end

    # Detect only build tools
    def detect_build_tools
      detect_category(BUILD_TOOLS)
    end

    # Detect only test frameworks
    def detect_test_frameworks
      detect_category(TEST_FRAMEWORKS)
    end

    # Return the primary ecosystem (most files matched)
    def primary_language
      ecosystems = detected_ecosystems
      return "unknown" if ecosystems.empty?

      ecosystems.max_by { |_, count| count }.first.to_s
    end

    # Suggest common commands based on detected toolchain
    def suggested_commands
      pm = detect_category(PACKAGE_MANAGERS)
      bt = detect_category(BUILD_TOOLS)
      tf = detect_category(TEST_FRAMEWORKS)

      cmds = {}

      # Install
      if (mgr = pm.first)
        cmds[:install] = install_command(mgr[:name])
      end

      # Test
      if (fw = tf.first)
        cmds[:test] = test_command(fw[:name])
      end

      # Build
      if (tool = bt.first)
        cmds[:build] = build_command(tool[:name])
      end

      cmds
    end

    private

    def detect_category(catalog)
      catalog.map do |name, spec|
        matched = spec[:files].select { |f| file_exists?(f) }
        next if matched.empty?

        {
          name: name,
          ecosystem: spec[:ecosystem],
          matched_files: matched,
          command: spec[:command]
        }
      end.compact
    end

    def detected_ecosystems
      all = [PACKAGE_MANAGERS, BUILD_TOOLS, TEST_FRAMEWORKS].flat_map do |catalog|
        detect_category(catalog).map { |r| r[:ecosystem] }
      end

      # tally is Ruby 2.7+; use inject for compatibility
      all.each_with_object(Hash.new(0)) { |e, h| h[e] += 1 }
    end

    def file_exists?(filename)
      File.exist?(File.join(@project_root, filename))
    end

    def install_command(pm)
      case pm
      when :npm     then "npm install"
      when :yarn    then "yarn install"
      when :pnpm    then "pnpm install"
      when :bun     then "bun install"
      when :pip     then "pip install -r requirements.txt"
      when :poetry  then "poetry install"
      when :pipenv  then "pipenv install"
      when :cargo   then "cargo build"
      when :gomod   then "go mod download"
      when :bundler then "bundle install"
      end
    end

    def test_command(fw)
      case fw
      when :jest      then "npx jest"
      when :vitest    then "npx vitest run"
      when :pytest    then "pytest"
      when :rspec     then "bundle exec rspec"
      when :minitest  then "ruby -Ilib:test test/**/*.rb"
      when :cargo_test then "cargo test"
      when :go_test   then "go test ./..."
      end
    end

    def build_command(tool)
      case tool
      when :vite    then "npx vite build"
      when :webpack then "npx webpack"
      when :rollup  then "npx rollup -c"
      when :gradle  then "./gradlew build"
      when :maven   then "mvn package"
      when :cmake   then "cmake --build ."
      when :make    then "make"
      when :rake    then "bundle exec rake"
      end
    end
  end
end
