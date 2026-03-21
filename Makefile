.PHONY: all validate generate inspect clean test schema verify-snapshot

all: validate generate

validate:
	@rake validate

schema:
	@echo "🔍 Validating YAML files against JSON Schema..."
	@bundle exec bin/validate-schemas
	@bundle exec bin/validate-platform-config

generate:
	@rake build

inspect:
	@bin/vibe inspect

clean:
	@rake clean

test:
	@rake test

verify-snapshot:
	@echo "🔍 Verifying snapshot consistency..."
	@ruby -Ilib:test test/test_vibe_cli.rb --name test_checked_in_runtimes_match_renderer
