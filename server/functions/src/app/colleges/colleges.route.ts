import { Router } from 'express';
import { createCollege, listColleges, updateCollege, deleteCollege, listCombined, createDepartment, listDepartments, updateDepartment, deleteDepartment } from './colleges.controller';
import { authenticate, requireVerifiedEmail } from '../../shared/middlewares/auth.middleware';
import { isSuperAdmin } from '../../shared/middlewares/role.middleware';

const router = Router();

/**
 * @openapi
 * /api/v1/colleges:
 *   get:
 *     summary: List all colleges (public)
 *     description: Fetches a list of all active colleges. Used during onboarding. Requires App Check in production but no Firebase Auth token.
 *     tags: [Colleges]
 *     security:
 *       - appCheck: []
 *     responses:
 *       200:
 *         description: List of colleges.
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id:
 *                     type: string
 *                     example: "col_123"
 *                   name:
 *                     type: string
 *                     example: "Anna University"
 *                   code:
 *                     type: string
 *                     example: "AU"
 */
router.get('/', listColleges);

router.get('/combined', listCombined);
router.get('/departments', listDepartments);
router.post('/departments', authenticate, requireVerifiedEmail, isSuperAdmin, createDepartment);
router.put('/departments/:id', authenticate, requireVerifiedEmail, isSuperAdmin, updateDepartment);
router.delete('/departments/:id', authenticate, requireVerifiedEmail, isSuperAdmin, deleteDepartment);

/**
 * @openapi
 * /api/v1/colleges:
 *   post:
 *     summary: Create a college (Superadmin)
 *     tags: [Colleges]
 *     security:
 *       - bearerAuth: []
 *         appCheck: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *                 example: "SSN College of Engineering"
 *               code:
 *                 type: string
 *                 example: "SSN"
 *               domains:
 *                 type: array
 *                 items:
 *                   type: string
 *                 example: ["ssn.edu.in"]
 *               city:
 *                 type: string
 *                 example: "Chennai"
 *             required:
 *               - name
 *               - code
 *     responses:
 *       201:
 *         description: College created.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "College created"
 *                 id:
 *                   type: string
 *                   example: "col_456"
 */
router.post('/', authenticate, requireVerifiedEmail, isSuperAdmin, createCollege);

/**
 * @openapi
 * /api/v1/colleges/{id}:
 *   put:
 *     summary: Update a college (Superadmin)
 *     description: Update any of the fields for a college. All fields are optional.
 *     tags: [Colleges]
 *     security:
 *       - bearerAuth: []
 *         appCheck: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *                 example: "SSN College of Engineering"
 *               code:
 *                 type: string
 *                 example: "SSN"
 *               domains:
 *                 type: array
 *                 items:
 *                   type: string
 *                 example: ["ssn.edu.in"]
 *               city:
 *                 type: string
 *                 example: "Kalavakkam"
 *     responses:
 *       200:
 *         description: College updated successfully.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "College updated"
 *       400:
 *         description: Validation error.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *                   example: "Validation error message"
 */
router.put('/:id', authenticate, requireVerifiedEmail, isSuperAdmin, updateCollege);

/**
 * @openapi
 * /api/v1/colleges/{id}:
 *   delete:
 *     summary: Delete a college (Superadmin)
 *     description: Soft-deletes a college by setting deletedAt timestamp.
 *     tags: [Colleges]
 *     security:
 *       - bearerAuth: []
 *         appCheck: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: College deleted.
 */
router.delete('/:id', authenticate, requireVerifiedEmail, isSuperAdmin, deleteCollege);

export default router;
