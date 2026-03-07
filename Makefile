VERSION=$(shell git describe --tags)

.PHONY: lint
lint:
	bundle exec rubocop
	bundle exec rails zeitwerk:check
	bundle exec bundler-audit
	bundle exec brakeman

.PHONY: check
check:
	bundle exec rubocop
	bundle-audit check --update

.PHONY: release
release:
	# Requires containerd for pulling and storing images (Settings/General in Docker Desktop)
	@echo publishing '$(VERSION)'
	docker build --platform linux/amd64,linux/arm64,linux/arm --push -t eargollo/soccer:$(VERSION) .
	@echo publishing latest
	docker build --platform linux/amd64,linux/arm64,linux/arm --push -t eargollo/soccer .