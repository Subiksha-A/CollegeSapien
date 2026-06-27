import { z } from 'zod';

/**
 * @openapi
 * components:
 *   schemas:
 *     User:
 *       type: object
 *       properties:
 *         uid:
 *           type: string
 *         name:
 *           type: string
 *         email:
 *           type: string
 *         collegeId:
 *           type: string
 *         collegeName:
 *           type: string
 *         department:
 *           type: string
 *         semester:
 *           type: integer
 *         role:
 *           type: string
 *           enum: [user, moderator, admin, superadmin]
 *         attendanceThreshold:
 *           type: integer
 *         profilePic:
 *           type: string
 *           format: uri
 *         isVerified:
 *           type: boolean
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 *         deletedAt:
 *           type: string
 *           format: date-time
 *           nullable: true
 */

export const UserSchema = z.object({
  uid: z.string(),
  name: z.string().min(2),
  email: z.string().email(),
  collegeId: z.string().optional(),
  collegeName: z.string(),
  department: z.string(),
  semester: z.number().int().min(1).max(10),
  role: z.enum(['user', 'moderator', 'admin', 'superadmin']).default('user'),
  attendanceThreshold: z.number().int().min(0).max(100).default(75),
  profilePic: z.string().url().optional(),
  isVerified: z.boolean().default(false),
  createdAt: z.any().optional(),
  updatedAt: z.any().optional(),
  deletedAt: z.any().optional().nullable(),
});

export type User = z.infer<typeof UserSchema>;

export const OnboardingSchema = z
  .object({
    name: z.string().min(2),
    collegeId: z.string().optional(),
    collegeName: z.string().min(3).optional(),
    department: z.string().min(1),
    semester: z.number().int().min(1).max(10),
    attendanceThreshold: z.number().int().min(50).max(100).default(75),
  })
  .refine(data => Boolean(data.collegeId || data.collegeName), {
    message: 'collegeId or collegeName is required',
    path: ['collegeId'],
  });

export const ProfileUpdateSchema = z.object({
  name: z.string().min(2).optional(),
  collegeId: z.string().min(1).optional(),
  department: z.string().min(1).optional(),
  semester: z.number().int().min(1).max(10).optional(),
  attendanceThreshold: z.number().int().min(50).max(100).optional(),
  profilePic: z.string().url().optional(),
});
