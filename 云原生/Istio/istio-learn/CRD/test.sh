# istio install
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.6.5 sh -

istioctl manifest apply --set profile=demo


export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')

# test app
curl -I -HHost:httpbin.example.com http://$INGRESS_HOST:$INGRESS_PORT/status/200

# 监控 httpbinv1
export V1_POD=$(kubectl get pod -l app=httpbin,version=v1 -o jsonpath={.items..metadata.name})

# 查看 v1 版本 httpbin 服务对应 Pod 的应用日志信息。
kubectl logs -f $V1_POD -c httpbin



#监控httpbinv2
export V2_POD=$(kubectl get pod -l app=httpbin,version=v2 -o jsonpath={.items..metadata.name})

# 查看 v2 版本 httpbin 服务对应 Pod 的应用日志信息。
kubectl logs -f $V2_POD -c httpbin