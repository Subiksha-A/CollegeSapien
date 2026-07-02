import type { NextFunction, Request, Response } from 'express';
import * as admin from 'firebase-admin';

const isAppCheckDisabled = () => {
  // App Check disabled by default. To enable enforcement, set ENFORCE_APP_CHECK=true.
  if (
    process.env.ENFORCE_APP_CHECK?.toLowerCase() === 'true' &&
    process.env.FUNCTIONS_EMULATOR !== 'true' &&
    process.env.NODE_ENV !== 'test'
  ) {
    return false; // Enforce App Check
  }
  return true; // Disabled (default)
};

export const enforceAppCheck = async (req: Request, res: Response, next: NextFunction) => {
  if (isAppCheckDisabled() || req.method === 'OPTIONS') {
    return next();
  }

  if (req.path.startsWith('/api/docs') || req.path === '/api/v1/health') {
    return next();
  }

  const token = req.header('X-Firebase-AppCheck');
  if (!token) {
    return res.status(401).json({ error: 'Unauthorized: Missing App Check token' });
  }

  try {
    await admin.appCheck().verifyToken(token);
    return next();
  } catch (error) {
    console.error('Error verifying App Check token:', error);
    return res.status(401).json({ error: 'Unauthorized: Invalid App Check token' });
  }
};
