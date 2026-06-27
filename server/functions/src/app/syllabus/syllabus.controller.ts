import { Response } from 'express';
import { AuthRequest } from '../../shared/middlewares/auth.middleware';
import * as admin from 'firebase-admin';
import { log } from '../../shared/logger';

const firestore = () => admin.firestore();

export const getSavedSubjects = async (req: AuthRequest, res: Response) => {
  try {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });

    const semester = parseInt(req.params.semester as string, 10);
    if (!semester || semester < 1 || semester > 10) {
      return res.status(400).json({ error: 'Valid semester (1-10) is required' });
    }

    const doc = await firestore()
      .collection('users')
      .doc(uid)
      .collection('syllabus')
      .doc(String(semester))
      .get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'No saved subjects found', subjects: null });
    }

    return res.status(200).json(doc.data());
  } catch (error: any) {
    log.error('getSavedSubjects error', { error: String(error), stack: error?.stack });
    return res.status(500).json({ error: error.message || 'Internal server error' });
  }
};

export const saveSubjects = async (req: AuthRequest, res: Response) => {
  try {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });

    const { semester, regulation, subjects } = req.body;

    if (!semester || semester < 1 || semester > 10) {
      return res.status(400).json({ error: 'Valid semester (1-10) is required' });
    }

    if (!regulation || typeof regulation !== 'string') {
      return res.status(400).json({ error: 'regulation is required' });
    }

    if (!Array.isArray(subjects) || subjects.length === 0) {
      return res.status(400).json({ error: 'subjects[] is required and must not be empty' });
    }

    const cleanedSubjects = subjects.map((s: any) => {
      const cleaned: Record<string, any> = {
        subjectCode: s.subjectCode || '',
        subjectName: s.subjectName || '',
        credits: typeof s.credits === 'number' ? s.credits : null,
        isElective: s.isElective === true,
      };
      if (s.electiveType) cleaned.electiveType = s.electiveType;
      if (s.courseType) cleaned.courseType = s.courseType;
      if (s.ltp) cleaned.ltp = s.ltp;
      if (typeof s.tcp === 'number') cleaned.tcp = s.tcp;
      if (s.category) cleaned.category = s.category;
      if (s.electiveStream) cleaned.electiveStream = s.electiveStream;
      return cleaned;
    });

    const data = {
      semester,
      regulation,
      subjects: cleanedSubjects,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await firestore()
      .collection('users')
      .doc(uid)
      .collection('syllabus')
      .doc(String(semester))
      .set(data, { merge: true });

    return res.status(200).json({ message: 'Subjects saved' });
  } catch (error: any) {
    log.error('saveSubjects error', { error: String(error), stack: error?.stack, body: req.body });
    return res.status(500).json({ error: error.message || 'Internal server error' });
  }
};
