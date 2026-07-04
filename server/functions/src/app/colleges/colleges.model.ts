import { z } from 'zod';

/**
 * @openapi
 * components:
 *   schemas:
 *     College:
 *       type: object
 *       required:
 *         - name
 *         - code
 *       properties:
 *         name:
 *           type: string
 *           minLength: 3
 *         code:
 *           type: string
 *           minLength: 2
 *         domains:
 *           type: array
 *           items:
 *             type: string
 *           description: Allowed email domains (e.g. ["ssn.edu.in"])
 *         city:
 *           type: string
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
export const CollegeSchema = z.object({
  name: z.string().min(3),
  code: z.string().min(2),
  domains: z.array(z.string()).optional(), // e.g. ["ssn.edu.in", "srm.edu.in"]
  city: z.string().optional(),
  createdAt: z.any().optional(),
  updatedAt: z.any().optional(),
  deletedAt: z.any().optional().nullable(),
});

export type College = z.infer<typeof CollegeSchema>;

export const DepartmentSchema = z.object({
  name: z.string().min(2),
  code: z.string().min(2),
  createdAt: z.any().optional(),
  updatedAt: z.any().optional(),
  deletedAt: z.any().optional().nullable(),
});

export type Department = z.infer<typeof DepartmentSchema>;
