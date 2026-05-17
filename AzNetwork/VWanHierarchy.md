```
Azure Virtual WAN (VWAN)
│
├── Virtual WAN Hub
│   ├── VPN Gateway
│   │   ├── VPN Connection
│   │   ├── Site-to-Site Connection
│   │   └── VNet Peering
│   │       └── Virtual Network (VNet)
│   │           ├── Subnet
│   │           ├── Network Security Group (NSG)
│   │           ├── Route Table
│   │           └── Virtual Machines (VMs)
│   │               ├── Network Interface Card (NIC)
│   │               │   ├── IP Configuration (Private/Public IP)
│   │               │   ├── Network Security Group (NSG)
│   │               │   ├── Load Balancer Configuration (if applicable)
│   │               │   └── IP Forwarding (if applicable)
│   │               ├── OS Disk (Managed)
│   │               └── Data Disks (Managed)
│   ├── ExpressRoute Gateway
│   │   └── ExpressRoute Circuit
│   ├── Azure Firewall
│   │   ├── Firewall Policy
│   │   └── Firewall Rules
│   └── Route Table
│       ├── Routes
│       └── Propagation Rules
│
├── VPN Site (For Site-to-Site Connectivity)
│   ├── VPN Device (On-Premises)
│   ├── VPN Gateway Configuration (Local Gateway)
│   └── Connection Configuration (VPN Connection to VWAN)
│
└── Virtual Network (VNet) (in case of non-VWAN setup, independent of VWAN)
    ├── Subnet
    ├── Network Security Group (NSG)
    ├── Route Table
    └── Virtual Machines (VMs)
        ├── Network Interface Card (NIC)
        │   ├── IP Configuration (Private/Public IP)
        │   ├── Network Security Group (NSG)
        │   ├── Load Balancer Configuration (if applicable)
        │   └── IP Forwarding (if applicable)
        ├── OS Disk (Managed)
        └── Data Disks (Managed)
```