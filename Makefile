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
build: ssh-install ssh-kubeconfig ssh-configure kubeseal

ssh-install: check-files generate_sealedsecret
	ssh $(SSH_HOST) mkdir -p bin
	scp install_k3s.sh switch_flux.sh k3os/install_flux.sh $(SSH_HOST):bin/
	ssh $(SSH_HOST) bin/install_k3s.sh
ssh-kubeconfig:
	scp $(SSH_HOST):/etc/rancher/k3s/k3s.yaml kubeconfig
	yq eval $(YQ_ARGS) '.clusters[0].cluster.server = "https://$(IP):6443"' kubeconfig
ssh-configure:
	scp $(OUTPUT_DIR)/sealed_secret.yaml $(SSH_HOST):$(K3S_MANIFEST_DIR)
	scp flux-install/* $(SSH_HOST):$(K3S_MANIFEST_DIR)



# config.yaml: check-files generate_sealedsecret
# 	cp -f k3os/config-template.yaml $(OUTPUT_DIR)/config.yaml
# 	yq eval $(YQ_ARGS) '.ssh_authorized_keys[0] = load_str("id_rsa.pub")'                       $(OUTPUT_DIR)/config.yaml
# 	yq eval $(YQ_ARGS) '.k3os.password = load_str("password.txt")'                              $(OUTPUT_DIR)/config.yaml
# 	yq eval $(YQ_ARGS) '.write_files[0].content = load_str("k3os/network.config")'              $(OUTPUT_DIR)/config.yaml
# 	yq eval $(YQ_ARGS) '.write_files[1].content = load_str("$(OUTPUT_DIR)/sealed_secret.yaml")' $(OUTPUT_DIR)/config.yaml
# 	yq eval $(YQ_ARGS) '.write_files[2].content = load_str("k3os/install_flux.sh")'             $(OUTPUT_DIR)/config.yaml
# 	yq eval $(YQ_ARGS) '.write_files[3].content = load_str("k3os/cron_update_images.sh")'       $(OUTPUT_DIR)/config.yaml

check-files:
	@which yq
	mkdir -p $(OUTPUT_DIR)
# 	test -f id_rsa.pub
# 	test -f password.txt
# 	test -f k3os/network.config
	test -f sealed.crt
	test -f sealed.key

generate_sealedsecret:
	cp k3os/sealed_secrets-template.yaml $(OUTPUT_DIR)/sealed_secret.yaml
	yq eval $(YQ_ARGS) '.stringData."tls.key" = load_str("sealed.key")'  $(OUTPUT_DIR)/sealed_secret.yaml
	yq eval $(YQ_ARGS) '.stringData."tls.crt" = load_str("sealed.crt")'  $(OUTPUT_DIR)/sealed_secret.yaml

kubeseal:  $(SECRETS)
	@echo "Updated Secrets"

$(SECRETS): gitops/%-sealed.yaml: secrets/%.yaml
	@which kubeseal > /dev/null
	@echo "Encrypt '$@' from file '$<'"
	kubeseal --cert sealed.crt -o yaml -f $< > $@
