# 🛡️ Secure Data: The Invisible Data Perimeter

## Overview

This repository contains a Terraform module to deploy the **"Secure Data: The Invisible Data Perimeter"** reference architecture. This Proof of Concept (PoC) demonstrates how to secure massive datasets containing Personally Identifiable Information (PII) against accidental exposure, internal misconfigurations, and external exfiltration.

Standard identity-based access control (IAM) is not enough to secure critical data. If a developer accidentally grants public access to a bucket or table, the data is exposed. This architecture addresses that risk head-on by creating **hard network perimeters** that explicitly **override** permissive IAM settings.

---

## 🏗️ Architecture: The 4 Pillars of Defense

1.  **The Vault (VPC Service Controls):** A network-level "denial by default" boundary that blocks access from unauthorized networks, regardless of IAM roles.
2.  **Automated Encryption (KMS Autokey):** Policy-driven Customer Managed Encryption Keys (CMEK) automatically provisioned for all datasets and buckets via folder-level delegation.
3.  **Intelligent Shield (Cloud DLP):** Automated PII discovery and query-time tokenization (masking) within BigQuery views using native DLP SQL functions.
4.  **Defense-in-Depth (Data Catalog):** Column-level security using Policy Tags to ensure only authorized users see sensitive raw data like SSNs.

### Architecture Flow
```mermaid
flowchart TD
    User((User/Attacker)) -->|1. Internet Access| VPC[VPC Service Perimeter]
    VPC -->|Blocked if Unapproved| BQ[(Secure BigQuery)]
    VPC -->|Blocked if Unapproved| GCS[(Secure GCS Buckets)]
    
    subgraph Inside Perimeter
    BQ --> DLP[DLP Tokenization View]
    BQ --> Tags[Data Catalog Policy Tags]
    end
    
    VPC -.->|Allowed via Context| Admin[Approved Identity]

    
