import { z } from 'zod';

export const CurriculumSubjectSchema = z.object({
  semester: z.union([z.string(), z.number()]).transform(v => String(v)),
  parent_semester: z.number().nullable().optional(),
  subject_code: z.string().optional().default(''),
  subject_name: z.string().min(1),
  course_type: z.string().optional().default(''),
  l_t_p: z.string().optional().default(''),
  tcp: z.number().nullable().optional(),
  credits: z.number().nullable().optional(),
  category: z.string().optional().default(''),
  is_elective: z.boolean().optional().default(false),
  elective_type: z.string().nullable().optional(),
  record_type: z.string().optional().default('core'),
  elective_stream: z.string().nullable().optional(),
  options_from: z.string().nullable().optional(),
});

export const CurriculumEnvelopeSchema = z.object({
  college: z.string().min(1),
  college_code: z.string().min(1),
  course: z.string().min(1),
  course_code: z.string().min(1),
  regulation: z.string().min(1),
  subjects: z.array(CurriculumSubjectSchema).min(1),
});

export const CurriculumUpdateSchema = z.object({
  college: z.string().min(1),
  collegeCode: z.string().min(1),
  course: z.string().min(1),
  courseCode: z.string().min(1),
  regulation: z.string().min(1),
  subjects: z.array(CurriculumSubjectSchema).min(1),
});

export type CurriculumEnvelope = z.infer<typeof CurriculumEnvelopeSchema>;
export type CurriculumUpdate = z.infer<typeof CurriculumUpdateSchema>;
export type CurriculumSubjectInput = z.infer<typeof CurriculumSubjectSchema>;

export const curriculumDocId = (collegeCode: string, courseCode: string, regulation: string) =>
  `${collegeCode}_${courseCode}_${regulation}`;
