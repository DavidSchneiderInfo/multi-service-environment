ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

all: install-services build-images install-dev-dependencies build-assets config up

install-services:
	test -d apps/blog || git clone https://github.com/DavidSchneiderInfo/blog.git apps/blog

build-images:
	# Generic images
	# Nginx
	docker build -t davidschneiderinfo/nginx:latest docker/nginx
	# Node
	docker build -t davidschneiderinfo/node:latest docker/node
	# PHP
	docker build -t davidschneiderinfo/php:latest docker/php
	# Blog app
	(cd apps/blog/;docker build -f docker/php/Dockerfile -t davidschneiderinfo/blog-php .)
	(cd apps/blog/;docker build -f docker/nginx/Dockerfile -t davidschneiderinfo/blog-nginx .)

push-images:
	# Generic images
	docker push davidschneiderinfo/nginx:latest
	docker push davidschneiderinfo/node:latest
	docker push davidschneiderinfo/php:latest
	# Blog app
	docker push davidschneiderinfo/blog-nginx:latest
	docker push davidschneiderinfo/blog-php:latest

pull-images:
	# Generic images
	docker pull davidschneiderinfo/nginx:latest
	docker pull davidschneiderinfo/node:latest
	docker pull davidschneiderinfo/php:latest
	# Blog app
	docker pull davidschneiderinfo/blog-nginx:latest
	docker pull davidschneiderinfo/blog-php:latest

install-dev-dependencies:
	docker run --rm \
		-v "${ROOT_DIR}/apps/blog:/var/www" \
		-w /var/www \
		davidschneiderinfo/node \
		npm install
	docker run --rm \
		-v "${ROOT_DIR}/apps/blog:/var/www" \
		-w /var/www \
		davidschneiderinfo/php \
		composer install --ignore-platform-reqs

install-prod-dependencies:
	docker run --rm \
		-v "${ROOT_DIR}/apps/blog:/var/www" \
		-w /var/www \
		davidschneiderinfo/php \
		composer install --ignore-platform-reqs
	docker run --rm \
		-v "${ROOT_DIR}/apps/blog:/var/www" \
		-w /var/www \
		davidschneiderinfo/node \
		npm install
	docker run --rm \
		-v "${ROOT_DIR}/apps/blog:/var/www" \
		-w /var/www \
		davidschneiderinfo/node \
		npm run build
	rm -rf apps/blog/node_modules

build-assets:
	docker-compose run --rm npm run build

config:
	test -f .env || cat .env.example > .env
	test -f apps/blog/.env || \
		cat apps/blog/.env.example > apps/blog/.env && \
		docker-compose run --rm blog-php artisan key:generate && \
		docker-compose run --rm blog-php artisan migrate

up:
	docker-compose up -d

down:
	docker-compose down

jenkins:
	./setup.sh