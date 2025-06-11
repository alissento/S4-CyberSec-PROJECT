# SecDrive: Secure Cloud Storage Solution

## Overview
SecDrive is a security-focused cloud storage application that prioritizes user data protection through advanced client-side encryption and comprehensive AWS security services integration. Built with a zero-knowledge architecture, SecDrive ensures that only users can access their encrypted data, providing enterprise-grade security for personal and professional file storage.

## Key Features

### Security & Encryption
- **Client-side AES-256-GCM encryption** - Files are encrypted in the browser before upload
- **Zero-knowledge architecture** - Server never sees unencrypted data or keys
- **AWS KMS integration** - Secure key management with envelope encryption
- **End-to-end encryption** for all stored files and user data
- **Secure key derivation** - Unique encryption keys per user session

### File Management
- **Secure file upload/download** with real-time progress tracking
- **File type detection** with intuitive icons and previews
- **Bulk file operations** - Upload and delete multiple files
- **Automatic file metadata storage** (name, size, type, upload date)
- **File integrity verification** through encrypted checksums

### User Experience
- **Modern responsive UI** built with Vue 3 and TailwindCSS
- **Real-time notifications** for all operations
- **Dark theme interface** with professional design
- **Firebase Authentication** integration for secure user management
- **Session-based encryption key caching** for improved performance

### Infrastructure Security
- **WAF protection** with AWS managed rule sets
- **CloudFront CDN** with SSL/TLS termination
- **API Gateway** with throttling and rate limiting
- **IAM role-based access controls** with least privilege principle

## Technology Stack

### Frontend (Vue.js SPA)
- **Vue 3** with Composition API and TypeScript
- **TailwindCSS** for responsive, modern styling
- **Shadcn/ui for Vue** - Accessible UI component library
- **Lucide Vue** - Consistent icon system
- **Pinia** - State management for user data
- **Vue Router** - Client-side routing
- **Firebase SDK** - Authentication integration
- **Web Crypto API** - Client-side encryption
- **Axios** - HTTP client for API communication

### Backend (Serverless AWS)
- **AWS Lambda** - 8 Python functions for different operations:
  - `store_user_data` - User registration and profile updates
  - `get_user_data` - Retrieve user files with presigned URLs
  - `get_user_profile` - Fetch user profile information
  - `generate_presigned_url` - Create secure S3 upload URLs
  - `confirm_upload` - Store file metadata after successful upload
  - `generate_data_key` - Create KMS data keys for encryption
  - `decrypt_data_key` - Decrypt KMS data keys for file access
  - `delete_file` - Remove files and metadata securely
- **API Gateway HTTP API** - RESTful endpoints with CORS support
- **Python 3.12** runtime with optimized performance

### Storage & Database
- **AWS S3** - Secure object storage for encrypted files
- **DynamoDB** - NoSQL database with two tables:
  - `secdrive_users` - User profiles and metadata
  - `secdrive_user_files` - File metadata with user indexing
- **S3 CORS configuration** - Secure cross-origin resource sharing

### Security & Infrastructure
- **AWS KMS** - Hardware security module for key management
- **Firebase Authentication** - User identity and access management
- **WAF v2** - Web application firewall with managed rule sets
- **CloudFront** - Global CDN with DDoS protection
- **ACM** - SSL/TLS certificate management
- **Route53** - DNS management and domain routing
- **AWS Shield** - DDoS protection and threat mitigation

### DevOps & Deployment
- **Terraform** - Infrastructure as Code for AWS resources
- **Vite** - Fast development build tool
- **TypeScript** - Type-safe development
- **Custom domain** - Professional branding with nknez.tech

## AWS Architecture
![AWS Architecture Diagram](docs/images/s4pp.png)

## Security Implementation

### Encryption Strategy
- **Client-side encryption** using AES-256-GCM before upload
- **Envelope encryption** with AWS KMS for key management
- **Unique data keys** generated per user session
- **IV (Initialization Vector)** randomization for each file
- **Base64 encoding** for secure key transmission

### Access Control
- **IAM roles with least privilege** - Each Lambda has minimal required permissions
- **Firebase token validation** for user authentication
- **User isolation** - Users can only access their own files
- **Presigned URL security** - Time-limited S3 access (1 hour expiry)

### Data Protection
- **TLS 1.2+ encryption** for all data in transit
- **S3 private buckets** with restricted public access
- **CORS policies** limiting cross-origin requests
- **Input validation** and sanitization across all endpoints

### Monitoring & Compliance
- **CloudWatch logging** for all Lambda functions
- **WAF metrics** and monitoring for threat detection
- **DynamoDB encryption at rest** using AWS managed keys
- **Audit trails** through CloudWatch logs
- **Error handling** with secure error messages

## Project Structure

```
S4-CyberSec-PROJECT/
├── secdrive/                    # Vue.js frontend application
│   ├── src/
│   │   ├── components/          # Vue components
│   │   │   ├── ui/             # Reusable UI components
│   │   │   ├── DashboardFiles.vue
│   │   │   ├── LoginPage.vue
│   │   │   └── ...
│   │   ├── utils/              # Utility functions
│   │   │   ├── encryption.ts   # Client-side crypto functions
│   │   │   └── encryptionService.ts
│   │   ├── stores/             # Pinia state stores
│   │   └── router/             # Vue Router configuration
│   ├── package.json
│   └── vite.config.ts
├── backend/                     # AWS Lambda functions (Python)
│   ├── store_user_data.py
│   ├── get_user_data.py
│   ├── generate_data_key.py
│   ├── decrypt_data_key.py
│   └── ...
├── terraform/                   # Infrastructure as Code
│   ├── lambda.tf               # Lambda function definitions
│   ├── lambda-iam.tf           # IAM roles and policies
│   ├── apigateway.tf           # API Gateway configuration
│   ├── s3.tf                   # S3 bucket setup
│   ├── dynamodb.tf             # Database tables
│   ├── kms.tf                  # Key management
│   ├── cloudfront.tf           # CDN configuration
│   └── waf.tf                  # Web application firewall
└── docs/
    └── images/
        └── s4pp.png            # Architecture diagram
```

## Getting Started

### Prerequisites
- AWS Account with appropriate permissions
- Terraform >= 1.0
- Node.js >= 18
- Firebase project setup

### Deployment
1. **Infrastructure Setup**
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

2. **Frontend Development**
   ```bash
   cd secdrive
   npm install
   npm run dev
   ```

3. **Production Build**
   ```bash
   npm run build
   # Deploy dist/ to S3 bucket
   ```

### Environment Configuration
- Configure Firebase authentication credentials
- Set up AWS KMS key permissions
- Update domain names in Terraform locals
- Configure CORS policies for your domain

## Status
This project is currently in active development as part of S4 CyberSecurity coursework, demonstrating enterprise-level security practices and modern cloud architecture patterns.

## Security Best Practices Implemented
- Zero-trust security model
- Defense in depth strategy
- Encryption at rest and in transit
- Principle of least privilege
- Regular security monitoring
- Secure software development lifecycle (SSDLC)
