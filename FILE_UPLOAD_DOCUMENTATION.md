# File Upload System Documentation

## Overview

This document describes the complete file upload mechanism implemented for the SecDrive application using S3 pre-signed URLs, Lambda functions, and DynamoDB for metadata storage.

## Architecture

The file upload system consists of three main components:

### 1. Frontend (Vue.js)
- **File**: `/secdrive/src/components/DashboardFiles.vue`
- **Functionality**: 
  - Drag-and-drop file upload interface
  - File preview for images
  - Upload progress tracking
  - File listing and download functionality

### 2. Backend Lambda Functions

#### Generate Pre-signed URL Lambda
- **File**: `/backend/generate_presigned_url.py`
- **Endpoint**: `POST /generatePresignedUrl`
- **Purpose**: Generates S3 pre-signed URLs for direct file uploads
- **Request Body**:
  ```json
  {
    "user_id": "string",
    "file_name": "string",
    "file_size": number,
    "content_type": "string"
  }
  ```
- **Response**:
  ```json
  {
    "presigned_url": "string",
    "file_id": "string",
    "s3_key": "string"
  }
  ```

#### Confirm Upload Lambda
- **File**: `/backend/confirm_upload.py`
- **Endpoint**: `POST /confirmUpload`
- **Purpose**: Stores file metadata in DynamoDB after successful S3 upload
- **Request Body**:
  ```json
  {
    "file_id": "string",
    "user_id": "string",
    "file_name": "string",
    "file_size": number,
    "s3_key": "string",
    "content_type": "string"
  }
  ```

#### Get User Data Lambda
- **File**: `/backend/get_user_data.py`
- **Endpoint**: `GET /getUserData?user_id={user_id}`
- **Purpose**: Retrieves user files with download URLs
- **Response**:
  ```json
  {
    "files": [
      {
        "id": "string",
        "name": "string",
        "type": "string",
        "size": "string",
        "modified": "string",
        "url": "string",
        "isFolder": false
      }
    ],
    "total_files": number
  }
  ```

### 3. Storage Layer

#### S3 Bucket
- **Name**: `secdrive-user-files-nknez`
- **Purpose**: Stores actual file content
- **CORS Configuration**: Allows PUT, POST, GET, DELETE methods for direct uploads

#### DynamoDB Table
- **Name**: `secdrive_user_files`
- **Purpose**: Stores file metadata
- **Schema**:
  - `file_id` (Primary Key)
  - `user_id` (GSI: secdrive_user_id_index)
  - `file_name`
  - `file_size`
  - `s3_key`
  - `content_type`
  - `upload_time`

## Upload Flow

1. **User selects files** in the Vue.js interface
2. **Frontend requests pre-signed URL** from `/generatePresignedUrl` endpoint
3. **Lambda generates unique file ID** and S3 key, returns pre-signed URL
4. **Frontend uploads file directly to S3** using the pre-signed URL
5. **Frontend confirms upload** by calling `/confirmUpload` endpoint
6. **Lambda stores file metadata** in DynamoDB
7. **Frontend refreshes file list** by calling `/getUserData`

## Download Flow

1. **User clicks download** on a file in the interface
2. **Frontend calls** the download URL (pre-signed URL for S3 object)
3. **File downloads directly** from S3 to user's device

## Security Features

- **Pre-signed URLs**: Limited-time access to S3 objects (1 hour expiry)
- **User Authentication**: Firebase Auth integration
- **CORS Policy**: Restricts cross-origin requests
- **IAM Permissions**: Lambda functions have minimal required S3 permissions
- **Private S3 Bucket**: No public access, all access through pre-signed URLs

## Infrastructure (Terraform)

### Modified Files:
- `/terraform/lambda.tf` - Added new Lambda functions and updated IAM policies
- `/terraform/apigateway.tf` - Added new API routes
- `/terraform/s3.tf` - Added CORS configuration for user files bucket

### Resources Created:
- 2 new Lambda functions (generate_presigned_url, confirm_upload)
- 2 new API Gateway routes
- S3 CORS configuration
- Updated IAM policy with S3 permissions

## Error Handling

- **Frontend**: Displays user-friendly error messages
- **Backend**: Comprehensive error logging and proper HTTP status codes
- **S3 Upload**: Retry logic for failed uploads
- **Rate Limiting**: API Gateway throttling protection

## Performance Considerations

- **Direct S3 Upload**: Bypasses server for file transfer
- **Pre-signed URLs**: Reduces server load
- **DynamoDB GSI**: Efficient user file queries
- **Client-side File Validation**: Reduces unnecessary API calls

## Testing

The system can be tested by:
1. Starting the Vue.js development server: `npm run dev`
2. Navigating to the Files dashboard
3. Uploading files using drag-and-drop or file selection
4. Verifying files appear in the list with download functionality

## Deployment

1. **Backend**: Lambda functions deployed via Terraform
2. **Infrastructure**: Applied via `terraform apply`
3. **Frontend**: Runs on development server at `http://localhost:5174`

## API Endpoints

- **Base URL**: `https://api.nknez.tech`
- **Generate Pre-signed URL**: `POST /generatePresignedUrl`
- **Confirm Upload**: `POST /confirmUpload`
- **Get User Files**: `GET /getUserData?user_id={user_id}`

## File Size and Type Support

- **Maximum File Size**: Limited by S3 and Lambda timeout (configurable)
- **Supported File Types**: All file types supported
- **File Type Detection**: Based on file extension
- **Image Preview**: Supported for image files in upload dialog

## Future Enhancements

- File versioning
- Folder organization
- File sharing capabilities
- Bulk operations (delete, move)
- File type restrictions per user
- Storage quotas
- File encryption at rest
