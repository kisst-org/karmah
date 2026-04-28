# module kube
This module has some actions that can help with managing kubernetes resources

## action kube-watch
Uses the `watch` command to periodically show some resources.
Example:
```
karmah apps/demo/tst kube-watch
```

## action kube-exec
run a command on a pod

## action kube-exec-it
start an interactive session in a pod

## option --replicas
specify the numbers of replicas for kube-scale and other actions

a special value `default` can be used

## option --resource
specify the resources certain actions can run in
