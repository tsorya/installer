clean:
	./hack/virt-delete-aio.sh || true
	rm -rf mydir

generate:
	mkdir -p mydir
	cp ./install-config.yaml mydir/
	OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE="quay.io/openshift-release-dev/ocp-release:4.6.1-x86_64" ./bin/openshift-install create ignition-configs --dir=mydir

start:
	./hack/virt-install-aio-ign.sh ./mydir/bootstrap.ign

start_master:
	VM_INT=2 ./hack/virt-install-aio-ign.sh ./mydir/master.ign

create_none_nets:
	./hack/virt-create-net-none.sh

start_none_bootstrap:
	./hack/update_bootstrap_ignition.py
	VM_INT=1 NETWORK=routed225 ./hack/virt-install-aio-ign.sh ./mydir/bootstrap.ign

start_none_master:
	cp ./hack/master.ign ./mydir/ -f
	VM_INT=2 NETWORK=routed226 ./hack/virt-install-aio-ign.sh ./mydir/master.ign
clean_none:
	./hack/virt-delete-none.sh || true
	rm -rf mydir
network:
	./hack/virt-create-net.sh

ssh:
	chmod 400 ./hack/ssh/key
	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ./hack/ssh/key core@192.168.126.10

image:
	curl -O -L https://releases-art-rhcos.svc.ci.openshift.org/art/storage/releases/rhcos-4.6/46.82.202008181646-0/x86_64/rhcos-46.82.202008181646-0-qemu.x86_64.qcow2.gz
	mv rhcos-46.82.202008181646-0-qemu.x86_64.qcow2.gz /tmp
	sudo gunzip /tmp/rhcos-46.82.202008181646-0-qemu.x86_64.qcow2.gz
