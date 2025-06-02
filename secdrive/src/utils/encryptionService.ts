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

// Global cache for current session to prevent race conditions
let currentSessionKey: { 
  userId: string; 
  cryptoKey: CryptoKey; 
  encryptedKey: string; 
  plaintextKey: string;
} | null = null;

// Get or generate a crypto key for the user session
export async function getCryptoKey(userId: string): Promise<{ cryptoKey: CryptoKey; encryptedKey: string }> {
  // First check in-memory cache to prevent race conditions
  if (currentSessionKey && currentSessionKey.userId === userId) {
    console.log('Using in-memory cached encryption key for user session');
    return { 
      cryptoKey: currentSessionKey.cryptoKey, 
      encryptedKey: currentSessionKey.encryptedKey 
    };
  }
  
  // Check if we have a key cached in session storage
  const cachedKey = sessionStorage.getItem(`encryption_key_${userId}`);
  const cachedEncryptedKey = sessionStorage.getItem(`encrypted_key_${userId}`);
  
  if (cachedKey && cachedEncryptedKey) {
    try {
      const cryptoKey = await importKeyFromBase64(cachedKey);
      console.log('Using session storage cached encryption key for user session');
      
      // Store in memory cache for immediate reuse
      currentSessionKey = {
        userId,
        cryptoKey,
        encryptedKey: cachedEncryptedKey,
        plaintextKey: cachedKey
      };
      
      return { cryptoKey, encryptedKey: cachedEncryptedKey };
    } catch (error) {
      console.warn('Failed to import cached key, generating new one:', error);
      // Clear invalid cache and fall through to generate new key
      sessionStorage.removeItem(`encryption_key_${userId}`);
      sessionStorage.removeItem(`encrypted_key_${userId}`);
      currentSessionKey = null;
    }
  }
  
  // Generate a new data key only if none is cached
  console.log('Generating new encryption key for user session');
  const keyData = await generateDataKey(userId);
  const cryptoKey = await importKeyFromBase64(keyData.plaintext_key);
  
  // Cache the key for this session
  sessionStorage.setItem(`encryption_key_${userId}`, keyData.plaintext_key);
  sessionStorage.setItem(`encrypted_key_${userId}`, keyData.encrypted_key);
  
  // Store in memory cache for immediate reuse
  currentSessionKey = {
    userId,
    cryptoKey,
    encryptedKey: keyData.encrypted_key,
    plaintextKey: keyData.plaintext_key
  };
  
  console.log('New encryption key generated and cached');
  return { cryptoKey, encryptedKey: keyData.encrypted_key };
}


 // Get a crypto key for decryption using an encrypted key
export async function getCryptoKeyForDecryption(userId: string, encryptedKey: string): Promise<CryptoKey> {
  console.log('Getting decryption key for encrypted key:', encryptedKey.substring(0, 32) + '...');
  
  // First check if this matches the current session key in memory
  if (currentSessionKey && 
      currentSessionKey.userId === userId && 
      currentSessionKey.encryptedKey === encryptedKey) {
    console.log('Requested key matches current in-memory session key, using cached key');
    return currentSessionKey.cryptoKey;
  }
  
  // Check if we have this specific key cached in session storage
  const cacheKey = `decryption_key_${encryptedKey.substring(0, 16)}`;
  const cachedKey = sessionStorage.getItem(cacheKey);
  
  if (cachedKey) {
    try {
      console.log('Using cached decryption key from session storage');
      return await importKeyFromBase64(cachedKey);
    } catch (error) {
      console.warn('Failed to import cached decryption key:', error);
      // Clear invalid cache and fall through to decrypt key
      sessionStorage.removeItem(cacheKey);
    }
  }
  
  // Check if this is the same as the current session key
  const sessionEncryptedKey = sessionStorage.getItem(`encrypted_key_${userId}`);
  if (sessionEncryptedKey === encryptedKey) {
    console.log('Requested key matches current session key, using cached session key');
    const sessionKey = sessionStorage.getItem(`encryption_key_${userId}`);
    if (sessionKey) {
      try {
        const cryptoKey = await importKeyFromBase64(sessionKey);
        // Cache it with the decryption key format too
        sessionStorage.setItem(cacheKey, sessionKey);
        
        // Update in-memory cache if not already set
        if (!currentSessionKey || currentSessionKey.userId !== userId) {
          currentSessionKey = {
            userId,
            cryptoKey,
            encryptedKey,
            plaintextKey: sessionKey
          };
        }
        
        return cryptoKey;
      } catch (error) {
        console.warn('Failed to import session key for decryption:', error);
      }
    }
  }
  
  // Decrypt the key using KMS
  console.log('Decrypting key using KMS');
  const keyData = await decryptDataKey(userId, encryptedKey);
  const cryptoKey = await importKeyFromBase64(keyData.plaintext_key);
  
  // Cache the decrypted key for this session
  sessionStorage.setItem(cacheKey, keyData.plaintext_key);
  console.log('Decryption key obtained and cached');
  
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
  
  // Clear in-memory cache as well
  currentSessionKey = null;
  console.log('All encryption caches cleared (session storage and memory)');
}
