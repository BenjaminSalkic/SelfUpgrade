const crypto = require('crypto');

// Use environment variable for encryption key, or generate a default for development
// IMPORTANT: Set ENCRYPTION_KEY in production (must be 32 bytes / 64 hex chars)
const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY
  ? Buffer.from(process.env.ENCRYPTION_KEY, 'hex')
  : crypto.scryptSync('default-dev-key-change-in-prod', 'salt', 32);

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 16;
const AUTH_TAG_LENGTH = 16;

/**
 * Encrypt sensitive data
 * @param {string} text - Plain text to encrypt
 * @returns {string} - Encrypted string (iv:authTag:encrypted)
 */
function encrypt(text) {
  if (!text || typeof text !== 'string') return text;

  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv(ALGORITHM, ENCRYPTION_KEY, iv);

  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');

  const authTag = cipher.getAuthTag();

  // Return iv:authTag:encrypted format
  return `${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted}`;
}

/**
 * Decrypt sensitive data
 * @param {string} encryptedText - Encrypted string (iv:authTag:encrypted)
 * @returns {string} - Decrypted plain text
 */
function decrypt(encryptedText) {
  if (!encryptedText || typeof encryptedText !== 'string') return encryptedText;

  // Check if it's in encrypted format
  const parts = encryptedText.split(':');
  if (parts.length !== 3) {
    // Not encrypted, return as-is (for backward compatibility)
    return encryptedText;
  }

  try {
    const [ivHex, authTagHex, encrypted] = parts;
    const iv = Buffer.from(ivHex, 'hex');
    const authTag = Buffer.from(authTagHex, 'hex');

    const decipher = crypto.createDecipheriv(ALGORITHM, ENCRYPTION_KEY, iv);
    decipher.setAuthTag(authTag);

    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');

    return decrypted;
  } catch (e) {
    // If decryption fails, return original (might be unencrypted legacy data)
    return encryptedText;
  }
}

/**
 * Hash data (one-way, for things like emails for lookup)
 * @param {string} text - Text to hash
 * @returns {string} - SHA-256 hash
 */
function hash(text) {
  if (!text) return text;
  return crypto.createHash('sha256').update(text).digest('hex');
}

/**
 * Encrypt an object's sensitive fields
 * @param {object} obj - Object with sensitive data
 * @param {string[]} fields - Array of field names to encrypt
 * @returns {object} - Object with encrypted fields
 */
function encryptFields(obj, fields) {
  if (!obj) return obj;
  const result = { ...obj };
  for (const field of fields) {
    if (result[field]) {
      result[field] = encrypt(result[field]);
    }
  }
  return result;
}

/**
 * Decrypt an object's sensitive fields
 * @param {object} obj - Object with encrypted data
 * @param {string[]} fields - Array of field names to decrypt
 * @returns {object} - Object with decrypted fields
 */
function decryptFields(obj, fields) {
  if (!obj) return obj;
  const result = { ...obj };
  for (const field of fields) {
    if (result[field]) {
      result[field] = decrypt(result[field]);
    }
  }
  return result;
}

module.exports = {
  encrypt,
  decrypt,
  hash,
  encryptFields,
  decryptFields
};
