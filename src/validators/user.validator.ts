import { z } from 'zod';

export const userRegistrationSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string()
    .min(8, 'Password must be at least 8 characters')
    .max(65, 'Password must be less than 65 characters'),
  firstName: z.string().optional(),
  lastName: z.string().optional(),
  userType: z.enum(['farmer', 'consumer'])
});

export const userLoginSchema = z.object({
  email: z.string().email(),
  password: z.string()
})