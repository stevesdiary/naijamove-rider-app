import express from 'express';
import { UserController } from '../controllers/user.controller';
import { validateRequest } from '../middleware/validate-request';
import { userRegistrationSchema } from '../validators/user.validator';

const router = express.Router();
const userController = new UserController();

router.post(
  '/register', 
  validateRequest(userRegistrationSchema),
  userController.register
);

router.post(
  '/login', 
  validateRequest(userLoginSchema),
  userController.login
);

export default router;
