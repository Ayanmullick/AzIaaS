```
📊 Compute Hierarchy

Azure Subscription
└── AKS Cluster
    ├── Node Pools (System & User)
    │   ├── Virtual Machine Scale Sets (VMSS)
    │   │   ├── Nodes (VMs / Kubelets)
    │   │   │   └── Pods (scheduled by kube-scheduler)
    │   │   │       └── Containers (each pod can have 1+ containers)
```

```
🌐Networking Hierarchy

Azure VNet
└── Subnet (AKS nodes or control plane, depending on setup)
    ├── Node NICs (each node has a NIC in subnet)
    │   └── Pod IPs (via CNI - either Azure CNI or kubenet)
    │       └── Container ports (inside pods)
    └── Load Balancer / Public IP (for service exposure)
        └── Kubernetes Services (type: LoadBalancer, ClusterIP, etc.)
            └── Endpoint (resolves to Pod IP)
```

```
📦Storage Hierarchy


AKS Cluster
└── Pods
    ├── Ephemeral Volume (emptyDir, container local scratch)
    └── Persistent Volume Claims (PVC)
        └── Persistent Volumes (PV)
            └── Azure Disk / Azure File / CSI StorageClass
                └── Azure Managed Disk or Azure Storage Account
```

```
Control Plane (Logical) Hierarchy

AKS Cluster
└── Namespace
    ├── Deployment
    │   └── ReplicaSet
    │       └── Pod
    │           └── Container
    └── Service
        └── Endpoint (maps to Pod IPs)
```        