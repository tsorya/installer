#!/bin/bash -x

function patchit {
    # allow etcd-operator to start the etcd cluster without minimum of 3 master nodes
    oc --kubeconfig ./auth/kubeconfig patch etcd cluster -p='{"spec": {"unsupportedConfigOverrides": {"useUnsupportedUnsafeNonHANonProductionUnstableEtcd": true}}}' --type=merge || return 1

    # allow cluster-authentication-operator to deploy OAuthServer without minimum of 3 master nodes
    oc --kubeconfig ./auth/kubeconfig patch authentications.operator.openshift.io cluster -p='{"spec": {"managementState": "Managed", "unsupportedConfigOverrides": {"useUnsupportedUnsafeNonHANonProductionUnstableOAuthServer": true}}}' --type=merge || return 1

    # patch ingress operator to run a single router pod
    oc patch --kubeconfig ./auth/kubeconfig -n openshift-ingress-operator ingresscontroller/default --patch '{"spec":{"replicas": 1}}' --type=merge || return 1

    return 0
}

while ! patchit; do
    echo "Waiting to try again..."
    sleep 10
done
touch patch.done

