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

## 🏢 Looking for Enterprise Isolation? (Zero-Trust VNet Edition)

This public repository is designed for fast, cost-effective deployments using public Azure endpoints.

For corporate environments building towards strict compliance frameworks (e.g., ISO 27001, KRITIS), I offer the **Enterprise VNet Edition** of this architecture.

**The Enterprise Edition includes:**
* **Complete Network Isolation:** Deployed entirely within your Virtual Network using VNet Integration.
* **Private Endpoints:** Azure Storage and Key Vault are accessed strictly via Azure Private Link. No public internet access.
* **Strict Firewalling:** Storage Account Network Rules configured to Deny All by default.
* **Zero-Trust Ready:** Hardened Terraform configuration ready for production.

🛒 **Enterprise VNet Edition:** The automated Lemon Squeezy checkout is currently undergoing final compliance checks. Until the store is fully live, please email me directly for access or a demo: **david@woitzik.dev**

**License Options:** Available for Single Organizations and as a Multi-Client License for IT Consultants/MSPs.

---
📧 **Contact:** david@woitzik.dev | 🌐 **GitHub:** @dwoitzik