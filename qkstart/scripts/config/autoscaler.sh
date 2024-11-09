read -p "Cluster name: " CLUSTER_NAME

template="$(curl https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml)"
template="$(echo "$template" | sed "s/<YOUR CLUSTER NAME>/$CLUSTER_NAME/")"

echo "$template" | kubectl apply -f -
