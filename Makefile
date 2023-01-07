OUTPUT_DIR=out
YQ_ARGS=--prettyPrint --no-colors --inplace
IP=10.0.0.16
SSH_HOST=root@$(IP)
K3S_MANIFEST_DIR=/var/lib/rancher/k3s/server/manifests
SECRETS = gitops/infra/common-secrets-sealed.yaml \
					gitops/vault/instance/vault-content-cloudflare-sealed.yaml \
					gitops/vault/instance/vault-content-secretids-sealed.yaml \
					gitops/vault/instance/vault-content-github-sealed.yaml


.PHONY: build ssh-install ssh-configure check-files generate_sealedsecret kubeseal
build: generate_sealedsecret kubeseal
install: ssh-install ssh-kubeconfig ssh-configure

ssh-install:
	ssh $(SSH_HOST) mkdir -p bin
	scp k3s/install_k3s.sh k3s/install_flux.sh $(SSH_HOST):bin/
	ssh $(SSH_HOST) bin/install_k3s.sh
ssh-kubeconfig:
	scp $(SSH_HOST):/etc/rancher/k3s/k3s.yaml kubeconfig
	yq eval $(YQ_ARGS) '.clusters[0].cluster.server = "https://$(IP):6443"' kubeconfig
ssh-configure: generate_sealedsecret
	scp $(OUTPUT_DIR)/sealed-secret.yaml $(SSH_HOST):$(K3S_MANIFEST_DIR)
	scp flux-install/* $(SSH_HOST):$(K3S_MANIFEST_DIR)

check-files:
	@which yq
	mkdir -p $(OUTPUT_DIR)
	test -f sealed.crt
	test -f sealed.key

generate_sealedsecret: check-files
	cp k3s/sealed-secrets-template.yaml $(OUTPUT_DIR)/sealed-secret.yaml
	yq eval $(YQ_ARGS) '.stringData."tls.key" = load_str("sealed.key")'  $(OUTPUT_DIR)/sealed-secret.yaml
	yq eval $(YQ_ARGS) '.stringData."tls.crt" = load_str("sealed.crt")'  $(OUTPUT_DIR)/sealed-secret.yaml

kubeseal:  $(SECRETS)
	@echo "Updated Secrets"

$(SECRETS): gitops/%-sealed.yaml: secrets/%.yaml
	@which kubeseal > /dev/null
	@echo "Encrypt '$@' from file '$<'"
	kubeseal --cert sealed.crt -o yaml -f $< > $@
