import { Request, Response } from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { User } from '../models';

export const register = async (req: Request, res: Response) => {
  try {
    const { firstName, lastName, email, password, role, location, farm_details } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await User.create({
      firstName,
      lastName,
      email,
      password: hashedPassword,
      role,
      location,
      farm_details,
    });

    res.status(201).json({ message: 'User registered successfully', user });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
};

export const login = async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ where: { email } });

    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign({ id: user.id, userType: user.userType }, process.env.JWT_SECRET!, { expiresIn: '1d' });
    res.json({ message: 'Login successful', token });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
};


