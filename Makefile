.PHONY: run build

run:
	bundle exec middleman server --watcher-force-polling

build:
	bundle exec middleman build --clean
