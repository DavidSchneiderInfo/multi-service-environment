all: install-services pull-images install-dev-dependencies build-assets config up

install-services:
	test -d apps/blog || git clone git@github.com:DavidSchneiderInfo/Blog.git apps/blog

build-images:
	# Blog app
	(cd apps/blog/;docker build -f docker/php/Dockerfile -t davidschneiderinfo/blog-php .)
	(cd apps/blog/;docker build -f docker/nginx/Dockerfile -t davidschneiderinfo/blog-nginx .)
	# Generic images
	docker build -t davidschneiderinfo/node:latest docker/node
	docker build -t davidschneiderinfo/composer:latest docker/composer

push-images:
	# Blog app
	docker push davidschneiderinfo/blog-nginx:latest
	docker push davidschneiderinfo/blog-php:latest
	# Generic images
	docker push davidschneiderinfo/node:latest
	docker push davidschneiderinfo/composer:latest

pull-images:
	# Blog app
	docker pull davidschneiderinfo/blog-nginx:latest
	docker pull davidschneiderinfo/blog-php:latest
	# Generic images
	docker pull davidschneiderinfo/node:latest
	docker pull davidschneiderinfo/composer:latest

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
