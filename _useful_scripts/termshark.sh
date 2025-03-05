kubectl run -it --rm --privileged --image=alpine --overrides='{"apiVersion": "v1", "spec": {"hostNetwork": true, "tolerations": [{"operator": "Exists"}], "nodeSelector": {"kubernetes.io/hostname": "ip-10-0-10-237.ap-northeast-2.compute.internal"}}}' debug -- /bin/ash -c 'apk add termshark && termshark'
kubectl delete pod debug --force
