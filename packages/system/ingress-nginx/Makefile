NAME=ingress-nginx
NAMESPACE=cozy-$(NAME)

include ../../../scripts/package-system.mk

update:
	rm -rf charts
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update ingress-nginx
	helm pull ingress-nginx/ingress-nginx --untar --untardir charts
	patch -p 3 < patches/add-metrics2.patch
	rm -f charts/ingress-nginx/templates/controller-deployment.yaml.orig
	rm -rf charts/ingress-nginx/changelog/
	#sed -i '/  type:/a \  allocateLoadBalancerNodePorts: false' charts/ingress-nginx/templates/controller-service.yaml
