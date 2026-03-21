# frozen_string_literal: true

require "yaml"
require "securerandom"
require "time"
require "fileutils"
require "open3"

module Vibe
  # Manages git worktrees for parallel task isolation
  class WorktreeManager
    attr_reader :repo_root, :worktrees_dir

    def initialize(repo_root = nil)
      @repo_root = repo_root || detect_repo_root
      @worktrees_dir = File.join(@repo_root, ".git", "vibe-worktrees")
    end

    # Create a new worktree for a task
    # @param task_name [String] Human-readable task name (used as branch suffix)
    # @param options [Hash]
    #   - :base_branch [String] Branch to base off (default: current branch)
    #   - :branch [String] Explicit branch name (auto-generated if omitted)
    # @return [Hash] Worktree info { id, path, branch, created_at }
    def create(task_name, options = {})
      assert_git_repo!

      id = SecureRandom.hex(4)
      branch = options[:branch] || "vibe/#{slugify(task_name)}-#{id}"
      base = options[:base_branch] || current_branch
      path = File.join(@worktrees_dir, id)

      FileUtils.mkdir_p(@worktrees_dir)

      run_git!("worktree", "add", "-b", branch, path, base)

      info = {
        "id" => id,
        "task_name" => task_name,
        "path" => path,
        "branch" => branch,
        "base_branch" => base,
        "created_at" => Time.now.iso8601,
        "status" => "active"
      }

      save_meta(id, info)
      info
    end

    # List all vibe-managed worktrees
    # @param filters [Hash] - :status [String] filter by status
    # @return [Array<Hash>]
    def list(filters = {})
      return [] unless Dir.exist?(@worktrees_dir)

      entries = Dir.glob(File.join(@worktrees_dir, "*", ".vibe-worktree.yaml"))
        .map { |f| YAML.safe_load(File.read(f), permitted_classes: [Time, Symbol], aliases: true) }
        .compact

      entries = entries.select { |e| e["status"] == filters[:status] } if filters[:status]
      entries.sort_by { |e| e["created_at"] }.reverse
    end

    # Get a single worktree by id
    def get(id)
      meta_path = File.join(@worktrees_dir, id, ".vibe-worktree.yaml")
      return nil unless File.exist?(meta_path)

      YAML.safe_load(File.read(meta_path), permitted_classes: [Time, Symbol], aliases: true)
    end

    # Mark a worktree as done (does not remove it yet)
    def finish(id)
      update_status(id, "finished")
    end

    # Remove a worktree and delete its branch
    # @param id [String] Worktree id
    # @param options [Hash] - :keep_branch [Boolean] skip branch deletion
    # @return [Boolean]
    def remove(id, options = {})
      info = get(id)
      return false unless info

      path = info["path"]

      # Remove the worktree from git
      run_git!("worktree", "remove", "--force", path)

      # Delete the branch unless asked to keep it
      unless options[:keep_branch]
        run_git!("branch", "-D", info["branch"])
      end

      # Remove metadata file (directory already gone after worktree remove)
      FileUtils.rm_rf(path)

      true
    end

    # Remove all finished worktrees
    # @return [Integer] number removed
    def cleanup
      finished = list(status: "finished")
      finished.each { |w| remove(w["id"]) }
      finished.size
    end

    # Status summary
    def status
      all = list
      {
        total: all.size,
        active: all.count { |w| w["status"] == "active" },
        finished: all.count { |w| w["status"] == "finished" },
        worktrees: all
      }
    end

    private

    def detect_repo_root
      out, status = Open3.capture2e("git", "rev-parse", "--show-toplevel")
      raise "Not inside a git repository" unless status.success?

      out.strip
    end

    def current_branch
      out, _status = Open3.capture2e("git", "-C", @repo_root, "rev-parse", "--abbrev-ref", "HEAD")
      out.strip
    end

    def assert_git_repo!
      raise "Not inside a git repository" unless Dir.exist?(File.join(@repo_root, ".git"))
    end

    def slugify(str)
      str.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")[0..30]
    end

    def run_git!(*args)
      out, status = Open3.capture2e("git", "-C", @repo_root, *args)
      raise "git #{args.join(' ')} failed: #{out}" unless status.success?

      out
    end

    def run_git(*args)
      out, _status = Open3.capture2e("git", "-C", @repo_root, *args)
      out
    end

    def save_meta(id, info)
      meta_path = File.join(@worktrees_dir, id, ".vibe-worktree.yaml")
      File.write(meta_path, YAML.dump(info))
    end

    def update_status(id, new_status)
      info = get(id)
      return false unless info

      info["status"] = new_status
      save_meta(id, info)
      true
    end
  end
end
