# 🔒 Azure ACME Certificate Automation (Serverless)

An automated, serverless Infrastructure-as-Code (IaC) deployment to manage Let's Encrypt certificates natively in Azure Key Vault.

This repository contains the Terraform automation required to deploy a fully functional, zero-maintenance certificate bot.

## 🚀 Overview

Managing SSL/TLS certificates manually is a security risk and an operational burden. This module deploys an automated ACME client into your Azure environment using a cost-effective Serverless (Consumption) architecture.

**Core Features:**
* **Fully Automated:** Automatic issuance and renewal of Let's Encrypt certificates.
* **Native Integration:** Certificates are directly pushed and stored securely in Azure Key Vault.
* **Cost-Optimized:** Utilizes the Azure App Service `Y1` (Consumption) tier, meaning you only pay for the compute seconds used during renewals (typically resulting in $0.00 monthly compute costs).
* **Zero-Trust Identity:** Uses System-Assigned Managed Identities for Key Vault and DNS Zone access. No hardcoded credentials.

## ⚙️ The Engine: Powered by Acmebot
The underlying application logic of this deployment is powered by the excellent open-source [Acmebot](https://github.com/shibayan/keyvault-acmebot) engine by Polymind.

While Polymind provides the core C# application that interacts with the Let's Encrypt API, this repository provides the **Terraform Infrastructure wrapper** to securely deploy, configure, and maintain the surrounding Azure ecosystem (Storage, Key Vault, IAM, and App Service Plans).

## 🛠️ Prerequisites

* [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5.0
* An active Azure Subscription
* An Azure DNS Zone (for DNS-01 validation)

## 📦 Quick Start

**1. Clone the repository and navigate to the terraform directory**
```bash
git clone https://github.com/dwoitzik/azure-acme-cert-automation.git
cd azure-acme-cert-automation/terraform
```
**2. Initialize Terraform**
```bash
terraform init
```
**3. Run the plan to review the resources**
```bash
terraform plan
```
**4. Deploy the infrastructure**
```bash
terraform apply
```
Once deployed, visit the Function App URL provided in the Terraform outputs to access the Acmebot Dashboard and configure your first certificate.

## 🏢 Enterprise VNet Edition

For corporate environments targeting strict compliance frameworks (e.g., **ISO 27001, KRITIS, NIS2**),
the Enterprise VNet Edition delivers a fully hardened, zero-trust architecture — saving you **4–8 hours
of architecture and security hardening work**.

### What's Included

| Feature | Free Edition | Enterprise Edition |
|---|---|---|
| Automated Let's Encrypt via Acmebot | ✅ | ✅ |
| Entra ID App Registration (Terraform-managed) | ✅ | ✅ |
| System-Assigned Managed Identity | ✅ | ✅ |
| RBAC Zero-Trust (DNS + Key Vault) | ✅ | ✅ |
| Serverless / Consumption Plan (Y1) | ✅ | ❌ |
| Dedicated App Service Plan (B1, always-on) | ❌ | ✅ |
| VNet Integration | ❌ | ✅ |
| Private Endpoints (Storage, Key Vault, Function) | ❌ | ✅ |
| Default-Deny Firewall Rules | ❌ | ✅ |
| No Public Network Access | ❌ | ✅ |
| HTTP/2 + FTPS Disabled + SCM Restricted | ❌ | ✅ |
| Private DNS Zone VNet Links | ❌ | ✅ |

### Pricing

| License | Price | For whom |
|---|---|---|
| **Single Organization** | €49 one-time | One deployment, one company |
| **Multi-Client / MSP** | €149 one-time | Unlimited deployments across clients |

Both licenses include the full Terraform source code and any future updates to this module.
The MSP license does **not** permit redistribution or resale of the code itself.

### Get Access

> 📩 **[Request access or a demo → david@woitzik.dev](mailto:david@woitzik.dev?subject=Enterprise%20VNet%20Edition%20-%20License%20Request)**
>
> Automated checkout coming soon. Current turnaround: **< 24 hours**.

---
📧 **Contact:** david@woitzik.dev | 🌐 **GitHub:** @dwoitzik
