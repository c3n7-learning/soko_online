# VERSION defines the container tag
VERSION ?= v0.0.1

upgrade-ingress-nginx:
	helm upgrade ingress-nginx ingress-nginx/ingress-nginx -f ./1.shared/nginx-values.yaml

deploy-backend-live:
	# Create namespace via config
	kubectl apply -f ./1.shared/1.live-namespace.yaml
	# Config Secrets
	VERSION=${VERSION} envsubst < ./2.config_secrets/1.live-backend-secrets.yaml | kubectl apply -f -
	# FPM Server
	VERSION=${VERSION} envsubst < ./3.fpm/1.live-backend-fpm-deployment.yaml | kubectl apply -f -
	VERSION=${VERSION} envsubst < ./3.fpm/2.live-backend-fpm-service.yaml | kubectl apply -f -
	# VERSION=${VERSION} envsubst < ./3.fpm/3.live-backend-fpm-autoscaler.yaml | kubectl apply -f -
	# NGINX Server
	VERSION=${VERSION} envsubst < ./4.nginx/1.live-backend-nginx-deployment.yaml | kubectl apply -f -
	VERSION=${VERSION} envsubst < ./4.nginx/2.live-backend-nginx-service.yaml | kubectl apply -f -
	# Queue worker
	# VERSION=${VERSION} envsubst < ./5.workers/1.live-backend-beanstalkd-deployment.yaml | kubectl apply -f -
	# VERSION=${VERSION} envsubst < ./5.workers/2.live-backend-worker-deployment.yaml | kubectl apply -f -
	# Scheduling
	# VERSION=${VERSION} envsubst < ./6.scheduler/1.live-backend-cron-deployment.yaml | kubectl apply -f -
