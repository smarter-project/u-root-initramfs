.PHONY: default
default: build

ROOTDIR ?= $(abspath .)
include common.mk 

$(SRC_DIR)/cpu:
	git clone --depth 1 https://github.com/u-root/cpu.git $(SRC_DIR)/cpu
	patch -N -p 1 -d $(SRC_DIR)/cpu -i $(ROOTDIR)/0001-Weird-cast-error-seems-to-cause-trouble.patch

$(BUILDS_DIR)/decpu: $(SRC_DIR)/cpu $(BUILDS_DIR)
	cd $(SRC_DIR)/cpu && go build -o $(BUILDS_DIR)/decpu $(SRC_DIR)/cpu/cmds/decpu/.

$(BUILDS_DIR)/cpud: $(SRC_DIR)/cpu $(BUILDS_DIR)
	cd $(SRC_DIR)/cpu && go build -tags mDNS -o $(BUILDS_DIR)/cpud $(SRC_DIR)/cpu/cmds/cpud/.

$(SRC_DIR)/u-root:
	git clone --depth 1 https://github.com/u-root/u-root.git $(SRC_DIR)/u-root

$(BUILDS_DIR)/u-root/u-root: $(SRC_DIR)/u-root
	mkdir -p $(BUILDS_DIR)/u-root
	cd $(SRC_DIR)/u-root && go mod tidy && go build -o $(BUILDS_DIR)/u-root

${HOME}/.ssh/identity:
	mkdir -p ${HOME}/.ssh
	ssh-keygen -N "" -f ${HOME}/.ssh/identity

$(BUILDS_DIR):
	mkdir -p $(BUILDS_DIR)

$(BUILDS_DIR)/identity.pub: ${HOME}/.ssh/identity $(BUILDS_DIR)
	cp ${HOME}/.ssh/identity.pub $(BUILDS_DIR)

$(BUILDS_DIR)/initramfs.cpio: $(BUILDS_DIR)/u-root/u-root $(BUILDS_DIR)/identity.pub $(SRC_DIR)/go.work
	$(BUILDS_DIR)/u-root/u-root -tags mDNS -o $(BUILDS_DIR)/initramfs.cpio -files ${BUILDS_DIR}/identity.pub:key.pub -files /mnt ./u-root/cmds/core/init ./u-root/cmds/core/gosh ./cpu/cmds/cpud

.PHONY: build
build: $(BUILDS_DIR)/initramfs.cpio $(BUILDS_DIR)/decpu $(BUILDS_DIR)/cpud

clean:
	rm -rf $(BUILDS_DIR)

nuke: clean
	rm -rf $(SRC_DIR)/cpu
	rm -rf $(SRC_DIR)/u-root
