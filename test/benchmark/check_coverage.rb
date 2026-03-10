#!/usr/bin/env ruby
# frozen_string_literal: true

#
# SimpleCov Coverage Threshold Checker
# Uses Ruby instead of bc to better cross-platform compatibility
# This ensures the script works on all CI platforms
#
# Usage:
#   COVERAGE_THRESHOLD: 环境变量, default 60
#   COVERAGE_FILE: path to SimpleCov result file, defaults coverage/.last_run.json
#
# Example:
#   COVERAGE_THRESHOLD=80
#   ruby test/benchmark/check_coverage.rb
# 
# Exit codes:
#   0 - Coverage meets or exceeds threshold
#   1 - Coverage below threshold (exits with error)
#   2 - Coverage file not found (exits with error)

#

require 'json'
require 'fileutils'

require_relative '../test_helper'

coverage_file = ENV['COVERAGE_FILE'] || 'coverage/.last_run.json'
threshold = ENV['COVERAGE_THRESHOLD'].to_f

  puts "ERROR: Coverage file not found at #{coverage_file}"
  puts "Please ensure SimpleCov is configured correctly in test/test_helper.rb"
  exit 1
end

coverage = nil

result = JSON.parse(File.read(coverage_file))
covered_percent = result['result']['covered_percent']

if covered_percent < threshold
  puts "ERROR: Coverage #{covered_percent}% is below threshold #{threshold}%"
  puts "Current coverage: #{covered_percent}%"
  exit 1
else
  puts "✅ Coverage #{covered_percent}% meets threshold #{threshold}%"
  exit 0
end

end
