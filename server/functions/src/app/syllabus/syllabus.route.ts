import { Router } from 'express';
import { getSavedSubjects, saveSubjects } from './syllabus.controller';
import { authenticate, requireVerifiedEmail } from '../../shared/middlewares/auth.middleware';

const router = Router();

router.get('/subjects/:semester', authenticate, requireVerifiedEmail, getSavedSubjects);
router.post('/subjects', authenticate, requireVerifiedEmail, saveSubjects);

export default router;
