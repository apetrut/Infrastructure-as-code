# Azure hybrid VPN gateway topology

This standalone Terraform root builds the three-VNet chain shown in the topology diagram:

```text
vnet1 (ASN 65010)  <--- VPN/BGP --->  vnet2 (ASN 65020)  <--- VPN/BGP --->  vnet3 (ASN 65030)
```

Each VNet has a `/16` address space, a dedicated `GatewaySubnet`, and four `/24` workload subnets (`subnet1` through `subnet4`). The three VNet ranges and workload subnet ranges are non-overlapping. One Linux VM is placed in `subnet1` of each VNet. Workload NSGs are associated with all workload subnets. The module also creates per-VM CPU alerts and per-gateway VPN tunnel ingress alerts sent to one email action group.

The diagram's CIDR text is partly hidden. The defaults here use `10.1.0.0/16`, `10.2.0.0/16`, and `10.3.0.0/16`, with workload subnets `10.<vnet>.1.0/24` through `10.<vnet>.4.0/24` and a `GatewaySubnet` at `10.<vnet>.255.224/27`. Review and change these ranges if they conflict with your network.

## Prerequisites

- Terraform 1.5 or later.
- Azure CLI authenticated to the intended subscription (`az login`), or another supported AzureRM provider authentication method.
- Permissions to create resource groups, networking, compute, and Azure Monitor resources.
- An SSH public key, an alert email address, and an IPsec shared key.

## Configure and deploy

Run these commands from this directory. `terraform.tfvars.example` is a template; copy it to `terraform.tfvars` and set the SSH public key and alert email. The shared key is deliberately supplied as an environment variable so it is not written to the tfvars file.

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
$env:ARM_SUBSCRIPTION_ID = "<subscription-id>"
$env:TF_VAR_vpn_shared_key = "<strong-random-shared-key>"
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out topology.tfplan
terraform apply topology.tfplan
```

Inspect the plan and confirm the subscription, ranges, gateway SKUs, and expected costs before applying. Azure VPN gateways can take a long time to provision and incur ongoing charges.

To remove resources created by this configuration:

```powershell
terraform destroy
```

## Notes

- Each gateway uses the BGP ASN shown in the diagram. VNet-to-VNet connections are created only for vnet1↔vnet2 and vnet2↔vnet3.
- Azure VNet-to-VNet gateway connections are configured at both ends of each link, with BGP enabled and a common IPsec shared key.
- The image appears to show `/24` ranges for individual subnet labels, but its CIDR labels are obscured. The supplied address plan is a configurable implementation assumption.
- The picture does not specify NSG rules, VM OS, gateway SKU, or alert thresholds. NSGs therefore use Azure defaults, VMs are Ubuntu Linux, and the CPU/tunnel alert thresholds are configurable defaults.
- The VPN tunnel ingress metric alert checks for low ingress traffic. It is a traffic signal, not a definitive tunnel-down alert; tune it for expected traffic or replace it with an operational metric available for the chosen gateway SKU and region.
- Remote state is not configured. Use an approved Azure Storage backend before sharing or automating this state.
