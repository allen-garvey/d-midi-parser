SRC = $(shell find ./ -type f -name '*.d')


all: dev

dev:
	dmd $(SRC) -of./bin/main -od./bin

