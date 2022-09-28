ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

all: install-services build-images install-dev-dependencies build-assets config up

install-services:
	test -d apps/blog || git clone https://github.com/DavidSchneiderInfo/blog.git apps/blog
	test -d apps/prototype || git clone https://github.com/DavidSchneiderInfo/prototype.git apps/prototype

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
	# Prototype app
	(cd apps/prototype/;docker build -f docker/php/Dockerfile -t davidschneiderinfo/prototype-php .)
	(cd apps/prototype/;docker build -f docker/nginx/Dockerfile -t davidschneiderinfo/prototype-nginx .)

push-images:
	# Generic images
	docker push davidschneiderinfo/nginx:latest
	docker push davidschneiderinfo/node:latest
	docker push davidschneiderinfo/php:latest
	# Blog app
	docker push davidschneiderinfo/blog-nginx:latest
	docker push davidschneiderinfo/blog-php:latest
	# Prototype app
	docker push davidschneiderinfo/prototype-nginx:latest
	docker push davidschneiderinfo/prototype-php:latest

pull-images:
	# Generic images
	docker pull davidschneiderinfo/nginx:latest
	docker pull davidschneiderinfo/node:latest
	docker pull davidschneiderinfo/php:latest
	# Blog app
	docker pull davidschneiderinfo/blog-nginx:latest
	docker pull davidschneiderinfo/blog-php:latest
	# Prototype app
	docker pull davidschneiderinfo/prototype-nginx:latest
	docker pull davidschneiderinfo/prototype-php:latest

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
	docker run --rm \
		-v "${ROOT_DIR}/apps/prototype:/var/www" \
		-w /var/www \
		davidschneiderinfo/node \
		npm install
	docker run --rm \
		-v "${ROOT_DIR}/apps/prototype:/var/www" \
		-w /var/www \
		davidschneiderinfo/php \
		composer install --ignore-platform-reqs

install-prod-dependencies:
	# Prototype app
	docker run --rm \
		-v "${ROOT_DIR}/apps/prototype:/var/www" \
		-w /var/www \
		davidschneiderinfo/php \
		composer install --ignore-platform-reqs
	docker run --rm \
		-v "${ROOT_DIR}/apps/prototype:/var/www" \
		-w /var/www \
		davidschneiderinfo/node \
		npm install
	docker run --rm \
		-v "${ROOT_DIR}/apps/prototype:/var/www" \
		-w /var/www \
		davidschneiderinfo/node \
		npm run build
	rm -rf apps/prototype/node_modules
	# Blog app
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
	# Prototype app
	docker run --rm \
		-v "${ROOT_DIR}/apps/blog:/var/www" \
		-w /var/www \
		davidschneiderinfo/node \
		npm run build
	# Blog app
	docker run --rm \
		-v "${ROOT_DIR}/apps/prototype:/var/www" \
		-w /var/www \
		davidschneiderinfo/node \
		npm run build

config:
	test -f .env || cat .env.example > .env
	# Blog app
	test -f apps/blog/.env || \
		cat apps/blog/.env.example > apps/blog/.env && \
		docker-compose run --rm blog-php artisan key:generate && \
		docker-compose run --rm blog-php artisan migrate
	# Prototype app
	test -f apps/prototype/.env || \
		cat apps/prototype/.env.example > apps/prototype/.env && \
		docker-compose run --rm prototype-php artisan key:generate && \
		docker-compose run --rm prototype-php artisan migrate

up:
	docker-compose up -d

down:
	docker-compose down