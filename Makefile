VENDOR_NAME=davidschneiderinfo

all: install-services build-images install-dev-dependencies build-assets config up

install-services:
	test -d apps/blog || git clone git@github.com:DavidSchneiderInfo/Blog.git apps/blog

build-images:
	docker build -t $(VENDOR_NAME)/service-nginx:latest docker/nginx
	docker build -t $(VENDOR_NAME)/service-php:latest docker/php
	docker build -t $(VENDOR_NAME)/service-node:latest docker/node
	docker build -t $(VENDOR_NAME)/service-composer:latest docker/composer

push-images:
	docker push $(VENDOR_NAME)/service-nginx:latest
	docker push $(VENDOR_NAME)/service-php:latest
	docker push $(VENDOR_NAME)/service-node:latest
	docker push $(VENDOR_NAME)/service-composer:latest

install-dev-dependencies:
	docker-compose run --rm composer install
	docker-compose run --rm npm install

install-prod-dependencies:
	docker-compose run --rm composer install --no-dev
	docker-compose run --rm npm install
	docker-compose run --rm npm run build
	rm -rf apps/blog/node_modules

build-assets:
	docker-compose run --rm npm run build

config:
	test -f .env || cat .env.example > .env
	test -f apps/blog/.env || \
		cat apps/blog/.env.example > apps/blog/.env && \
		docker-compose run --rm php artisan key:generate && \
		docker-compose run --rm php artisan migrate	

up:
	docker-compose up -d

down:
	docker-compose down
