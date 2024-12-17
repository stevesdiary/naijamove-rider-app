import express from 'express';
// import  UserController  from '../controllers/user.controller';
// import { validateRequest } from '../middleware';
import { userRegistrationSchema, userLoginSchema } from '../validators/user.validator';

const router = express.Router();
// const userController = new UserController();

// router.post('/register', userController.register);

// router.post('/login', userController.login);

export default router;
