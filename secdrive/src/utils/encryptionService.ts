import { api } from '@/config';
import { importKeyFromBase64 } from './encryption';

export interface DataKeyResponse {
  plaintext_key: string;
  encrypted_key: string;
  key_id: string;
}

export interface DecryptKeyResponse {
  plaintext_key: string;
  key_id: string;
}


 // Generate a new data key for encrypting files

export async function generateDataKey(userId: string): Promise<DataKeyResponse> {
  try {
    const response = await api.post('/generateDataKey', {
      user_id: userId
    });
    
    return response.data;
  } catch (error) {
    console.error('Failed to generate data key:', error);
    throw new Error('Failed to generate encryption key');
  }
}


 // Decrypt a data key for decrypting files

export async function decryptDataKey(userId: string, encryptedKey: string): Promise<DecryptKeyResponse> {
  try {
    const response = await api.post('/decryptDataKey', {
      user_id: userId,
      encrypted_key: encryptedKey
    });
    
    return response.data;
  } catch (error) {
    console.error('Failed to decrypt data key:', error);
    throw new Error('Failed to decrypt encryption key');
  }
}

// Get or generate a crypto key for the user session

export async function getCryptoKey(userId: string): Promise<{ cryptoKey: CryptoKey; encryptedKey: string }> {
  // Check if we have a key cached in session storage
  const cachedKey = sessionStorage.getItem(`encryption_key_${userId}`);
  const cachedEncryptedKey = sessionStorage.getItem(`encrypted_key_${userId}`);
  
  if (cachedKey && cachedEncryptedKey) {
    try {
      const cryptoKey = await importKeyFromBase64(cachedKey);
      return { cryptoKey, encryptedKey: cachedEncryptedKey };
    } catch (error) {
      console.warn('Failed to import cached key, generating new one:', error);
      // Fall through to generate new key
    }
  }
  
  // Generate a new data key
  const keyData = await generateDataKey(userId);
  const cryptoKey = await importKeyFromBase64(keyData.plaintext_key);
  
  // Cache the key for this session (plaintext key only exists in memory)
  sessionStorage.setItem(`encryption_key_${userId}`, keyData.plaintext_key);
  sessionStorage.setItem(`encrypted_key_${userId}`, keyData.encrypted_key);
  
  return { cryptoKey, encryptedKey: keyData.encrypted_key };
}


 // Get a crypto key for decryption using an encrypted key
export async function getCryptoKeyForDecryption(userId: string, encryptedKey: string): Promise<CryptoKey> {
  // Check if we have this specific key cached
  const cacheKey = `decryption_key_${encryptedKey.substring(0, 16)}`;
  const cachedKey = sessionStorage.getItem(cacheKey);
  
  if (cachedKey) {
    try {
      return await importKeyFromBase64(cachedKey);
    } catch (error) {
      console.warn('Failed to import cached decryption key:', error);
      // Fall through to decrypt key
    }
  }
  
  // Decrypt the key using KMS
  const keyData = await decryptDataKey(userId, encryptedKey);
  const cryptoKey = await importKeyFromBase64(keyData.plaintext_key);
  
  // Cache the decrypted key for this session
  sessionStorage.setItem(cacheKey, keyData.plaintext_key);
  
  return cryptoKey;
}


 // Clear all cached encryption keys

export function clearEncryptionCache(): void {
  const keys = Object.keys(sessionStorage);
  keys.forEach(key => {
    if (key.startsWith('encryption_key_') || key.startsWith('encrypted_key_') || key.startsWith('decryption_key_')) {
      sessionStorage.removeItem(key);
    }
  });
}
