/**
 * Client-side encryption utilities using Web Crypto API
 */

export interface EncryptionResult {
  encryptedData: ArrayBuffer;
  iv: ArrayBuffer;
}

export interface DecryptionParams {
  encryptedData: ArrayBuffer;
  key: CryptoKey;
  iv: ArrayBuffer;
}

/**
 * Convert base64 string to ArrayBuffer
 */
export function base64ToArrayBuffer(base64: string): ArrayBuffer {
  const binaryString = atob(base64);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes.buffer;
}

/**
 * Convert ArrayBuffer to base64 string
 */
export function arrayBufferToBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binaryString = '';
  for (let i = 0; i < bytes.byteLength; i++) {
    binaryString += String.fromCharCode(bytes[i]);
  }
  return btoa(binaryString);
}

/**
 * Import a raw key from base64 string for AES-GCM encryption
 */
export async function importKeyFromBase64(keyData: string): Promise<CryptoKey> {
  const keyBuffer = base64ToArrayBuffer(keyData);
  
  return await crypto.subtle.importKey(
    'raw',
    keyBuffer,
    { name: 'AES-GCM' },
    false, // Not extractable
    ['encrypt', 'decrypt']
  );
}

/**
 * Encrypt a file using AES-GCM
 */
export async function encryptFile(file: File, key: CryptoKey): Promise<EncryptionResult> {
  // Generate a random IV (Initialization Vector)
  const iv = crypto.getRandomValues(new Uint8Array(12)); // 96-bit IV for GCM
  
  // Read file as ArrayBuffer
  const fileBuffer = await file.arrayBuffer();
  
  // Encrypt the file data
  const encryptedData = await crypto.subtle.encrypt(
    {
      name: 'AES-GCM',
      iv: iv
    },
    key,
    fileBuffer
  );
  
  return {
    encryptedData,
    iv: iv.buffer
  };
}

/**
 * Decrypt file data using AES-GCM
 */
export async function decryptFileData(params: DecryptionParams): Promise<ArrayBuffer> {
  const decryptedData = await crypto.subtle.decrypt(
    {
      name: 'AES-GCM',
      iv: params.iv
    },
    params.key,
    params.encryptedData
  );
  
  return decryptedData;
}

/**
 * Create an encrypted blob that includes the IV and encrypted data
 */
export function createEncryptedBlob(encryptedData: ArrayBuffer, iv: ArrayBuffer): Blob {
  // Create a structure that includes both IV and encrypted data
  const ivArray = new Uint8Array(iv);
  const dataArray = new Uint8Array(encryptedData);
  
  // Combine IV (12 bytes) + encrypted data
  const combined = new Uint8Array(ivArray.length + dataArray.length);
  combined.set(ivArray, 0);
  combined.set(dataArray, ivArray.length);
  
  return new Blob([combined], { type: 'application/octet-stream' });
}

/**
 * Extract IV and encrypted data from an encrypted blob
 */
export async function extractFromEncryptedBlob(blob: Blob): Promise<{ iv: ArrayBuffer; encryptedData: ArrayBuffer }> {
  const buffer = await blob.arrayBuffer();
  const array = new Uint8Array(buffer);
  
  // Extract IV (first 12 bytes) and encrypted data (rest)
  const iv = array.slice(0, 12).buffer;
  const encryptedData = array.slice(12).buffer;
  
  return { iv, encryptedData };
}

/**
 * Extract IV and encrypted data from a downloaded encrypted file
 */
export async function extractFromEncryptedArrayBuffer(buffer: ArrayBuffer): Promise<{ iv: ArrayBuffer; encryptedData: ArrayBuffer }> {
  const array = new Uint8Array(buffer);
  
  // Extract IV (first 12 bytes) and encrypted data (rest)
  const iv = array.slice(0, 12).buffer;
  const encryptedData = array.slice(12).buffer;
  
  return { iv, encryptedData };
}

/**
 * Download and decrypt a file
 */
export async function downloadAndDecryptFile(
  url: string, 
  fileName: string, 
  encryptionKey: CryptoKey
): Promise<void> {
  try {
    console.log('Starting download and decrypt for:', fileName);
    console.log('Download URL:', url);
    
    // Download the encrypted file
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Download failed: ${response.statusText}`);
    }
    
    const encryptedBuffer = await response.arrayBuffer();
    console.log('Downloaded encrypted buffer size:', encryptedBuffer.byteLength);
    
    // Extract IV and encrypted data
    const { iv, encryptedData } = await extractFromEncryptedArrayBuffer(encryptedBuffer);
    console.log('Extracted IV size:', iv.byteLength);
    console.log('Extracted encrypted data size:', encryptedData.byteLength);
    
    // Decrypt the file
    console.log('Starting decryption...');
    const decryptedData = await decryptFileData({
      encryptedData,
      key: encryptionKey,
      iv
    });
    console.log('Decrypted data size:', decryptedData.byteLength);
    
    // Create blob and download
    const blob = new Blob([decryptedData]);
    const downloadUrl = URL.createObjectURL(blob);
    
    const link = document.createElement('a');
    link.href = downloadUrl;
    link.download = fileName;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    
    // Clean up
    URL.revokeObjectURL(downloadUrl);
    console.log('Download completed successfully');
    
  } catch (error) {
    console.error('Download and decrypt failed:', error);
    throw error;
  }
}
