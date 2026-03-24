# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'timeout'
require 'rbconfig'
require_relative 'platform_utils'

module Vibe
  # Installer for the gstack skill pack (clones repo and sets up skills directory).
  module GstackInstaller
    include PlatformUtils

    GSTACK_REPO_URLS = [
      'https://github.com/garrytan/gstack.git',
      'https://gitee.com/mirrors/gstack.git' # China mirror
    ].freeze

    GSTACK_PLATFORM_PATHS = {
      'unified' => '~/.config/skills/gstack',      # 统一存储位置（优先）
      'claude-code' => '~/.claude/skills/gstack',  # Claude Code 软链接位置
      'opencode' => '~/.config/opencode/skills/gstack'  # OpenCode 软链接位置（兼容）
    }.freeze

    CLONE_TIMEOUT = 60
    MAX_RETRIES = 3

    def self.install_gstack(platform = nil)
      # 始终使用统一存储位置，然后通过软链接共享
      target_dir = File.expand_path(GSTACK_PLATFORM_PATHS['unified'])

      unless system('git', '--version', out: File::NULL, err: File::NULL)
        puts
        puts '   ❌ Git is not installed. Please install Git first.'
        return false
      end

      puts
      puts '   Installing gstack Skill Pack...'

      # 检查统一位置是否已安装
      if Dir.exist?(target_dir) && gstack_markers_present?(target_dir)
        puts "   ✓ gstack already installed at #{target_dir}"
        create_platform_symlinks(target_dir)
        return run_setup(target_dir)
      end

      parent_dir = File.dirname(target_dir)
      FileUtils.mkdir_p(parent_dir) unless Dir.exist?(parent_dir)

      # Remove incomplete install if present
      if Dir.exist?(target_dir) && !gstack_markers_present?(target_dir)
        puts '   ⚠️  Incomplete installation found, removing...'
        FileUtils.rm_rf(target_dir)
      end

      puts
      puts '   Cloning gstack repository...'
      puts "   Target: #{target_dir}"

      success, used_url = clone_from_mirrors(GSTACK_REPO_URLS, target_dir)
      unless success
        puts '   ❌ Failed to clone from all available sources'
        puts
        puts '   Troubleshooting:'
        puts '   - Check your internet connection'
        puts '   - Check if a firewall is blocking Git'
        puts "   - Try manual clone: git clone #{GSTACK_REPO_URLS.first} #{target_dir}"
        return false
      end

      puts "   ✓ Cloned successfully from #{used_url}"

      create_platform_symlinks(target_dir)
      run_setup(target_dir)
    rescue StandardError => e
      puts "   ❌ Installation failed: #{e.message}"
      puts "   #{e.backtrace.first(5).join("\n   ")}" if ENV['VIBE_DEBUG']
      false
    end

    def self.run_setup(target_dir)
      setup_script = File.join(target_dir, 'setup')

      unless File.exist?(setup_script)
        puts '   ⚠️  setup script not found, skipping post-install'
        puts '   ✅ gstack cloned but /browse may not work without running setup'
        return true
      end

      # 预检查 Bun 环境
      bun_installed = check_bun_installed
      unless bun_installed
        puts
        puts '   ⚠️  Bun is not installed.'
        puts '   gstack skills (review, ship, etc.) will work fine without Bun.'
        puts '   However, browser-based skills (/browse, /qa) require Bun v1.0+.'
        puts
        puts '   To install Bun:'
        puts '   • macOS/Linux: curl -fsSL https://bun.sh/install | bash'
        puts '   • Windows: winget install Oven-sh.Bun'
        puts '   • Or visit: https://bun.sh'
        puts
        puts "   After installing Bun, run: cd #{target_dir} && ./setup"
        puts
        return true
      end

      puts
      puts "   ⚠️  About to execute: #{setup_script}"
      puts(
        "   Source: #{GSTACK_REPO_URLS.first} " \
          '(floating HEAD — not pinned to a tag or SHA)'
      )
      puts '   The setup script installs Bun dependencies and builds the /browse binary.'
      puts "   Review it at: #{setup_script}"
      puts
      puts '   Running gstack setup...'

      _stdout, stderr, status = Open3.capture3('bash', setup_script, chdir: target_dir)

      if status.success?
        puts '   ✅ gstack installed successfully!'
        puts "   Location: #{target_dir}"
      else
        # Setup failure is non-fatal — skills still work, just /browse won't
        puts '   ⚠️  setup completed with warnings (browse skills may not work)'
        puts "   #{stderr.strip}" unless stderr.empty?
        puts '   Other gstack skills (review, ship, etc.) will work fine.'
        puts "   To fix /browse later: cd #{target_dir} && bun install && bun run build"
      end
      true
    end

    def self.verify_installation(platform = nil)
      platform ||= 'unified'
      target_dir = File.expand_path(
        GSTACK_PLATFORM_PATHS[platform] || GSTACK_PLATFORM_PATHS['unified']
      )

      issues = []

      return { success: false, issues: ["gstack not installed at #{target_dir}"] } unless Dir.exist?(target_dir)

      %w[SKILL.md VERSION setup].each do |marker|
        issues << "Missing marker file: #{marker}" unless File.exist?(File.join(target_dir, marker))
      end

      version = nil
      version_file = File.join(target_dir, 'VERSION')
      version = File.read(version_file).strip if File.exist?(version_file)

      skills_count = Dir.children(target_dir).count do |entry|
        File.directory?(File.join(target_dir, entry)) &&
          File.exist?(File.join(target_dir, entry, 'SKILL.md'))
      end

      browse_ready = File.exist?(File.join(target_dir, 'browse', 'dist', 'browse'))

      {
        success: issues.empty?,
        location: target_dir,
        version: version,
        skills_count: skills_count,
        browse_ready: browse_ready,
        issues: issues
      }
    end

    def self.uninstall_gstack(_platform = nil)
      GSTACK_PLATFORM_PATHS.each_value do |path|
        expanded = File.expand_path(path)
        if Dir.exist?(expanded)
          puts "  Removing: #{expanded}"
          FileUtils.rm_rf(expanded)
        end
      end
      puts 'gstack uninstalled.'
    end

    # --- Private helpers ---

    def self.clone_from_mirrors(urls, target)
      urls.each_with_index do |url, index|
        puts "   Trying source #{index + 1}/#{urls.size}: #{url}"

        success = clone_with_retry(url, target)
        return [true, url] if success

        puts "   ✗ Failed to clone from #{url}"
        puts
      end

      [false, nil]
    end

    def self.clone_with_retry(url, target)
      attempt = 0

      while attempt < MAX_RETRIES
        attempt += 1

        begin
          Timeout.timeout(CLONE_TIMEOUT) do
            _stdout, stderr, status = Open3.capture3(
              'git', 'clone', '--depth', '1', url, target
            )

            return true if status.success?

            puts "   ⚠️  Attempt #{attempt}/#{MAX_RETRIES} failed"
            puts "   #{stderr.strip}" unless stderr.empty?
            # Clean up failed clone
            FileUtils.rm_rf(target) if Dir.exist?(target)
          end
        rescue Timeout::Error
          puts(
            "   ⚠️  Attempt #{attempt}/#{MAX_RETRIES} timed out " \
              "after #{CLONE_TIMEOUT}s"
          )
          FileUtils.rm_rf(target) if Dir.exist?(target)
        rescue StandardError => e
          puts "   ⚠️  Attempt #{attempt}/#{MAX_RETRIES} error: #{e.message}"
          FileUtils.rm_rf(target) if Dir.exist?(target)
        end

        next unless attempt < MAX_RETRIES

        sleep_time = attempt * 2
        puts "   Retrying in #{sleep_time} seconds..."
        sleep(sleep_time)
      end

      false
    end

    def self.gstack_markers_present?(dir)
      %w[SKILL.md VERSION setup].all? { |f| File.exist?(File.join(dir, f)) }
    end

    # 检查 Bun 是否已安装（v1.0+）
    def self.check_bun_installed
      _stdout, _stderr, status = Open3.capture3('bun', '--version')
      return false unless status.success?

      version = _stdout.strip
      return false if version.nil? || version.empty?

      # 解析版本号，确保 >= 1.0.0
      begin
        major = version.to_s.match(/v?(\d+)\./)&.captures&.first&.to_i
        major && major >= 1
      rescue StandardError
        false
      end
    end

    # 为各平台创建软链接到统一存储位置
    def self.create_platform_symlinks(source_dir)
      puts
      puts '   Creating platform symlinks...'

      # 需要创建软链接的平台路径（排除 unified 自身）
      symlink_paths = {
        'claude-code' => GSTACK_PLATFORM_PATHS['claude-code'],
        'opencode' => GSTACK_PLATFORM_PATHS['opencode']
      }

      symlink_paths.each do |platform, path|
        symlink_path = File.expand_path(path)
        
        # 如果已经是正确的软链接，跳过
        if File.symlink?(symlink_path) && File.readlink(symlink_path) == source_dir
          puts "   ✓ #{platform} symlink already correct"
          next
        end

        # 如果存在但不是软链接，跳过并警告
        if File.exist?(symlink_path) && !File.symlink?(symlink_path)
          puts "   ⚠️  #{platform} path exists but is not a symlink (#{symlink_path})"
          next
        end

        # 如果存在旧的错误软链接，删除它
        if File.symlink?(symlink_path)
          puts "   → Updating #{platform} symlink"
          FileUtils.rm(symlink_path)
        else
          puts "   → Creating #{platform} symlink"
        end

        # 创建父目录
        parent_dir = File.dirname(symlink_path)
        FileUtils.mkdir_p(parent_dir) unless Dir.exist?(parent_dir)

        # 创建软链接
        begin
          FileUtils.ln_s(source_dir, symlink_path)
          puts "   ✓ #{platform}: #{symlink_path}"
        rescue StandardError => e
          puts "   ⚠️  Failed to create #{platform} symlink: #{e.message}"
        end
      end
    end
  end
end
