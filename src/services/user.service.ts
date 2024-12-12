// src/services/user.service.ts
import { UserRepository } from '../repositories/user.repository';
import { User } from '../models/user.model';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

export class UserService {
  private userRepository: UserRepository;

  constructor() {
    this.userRepository = new UserRepository();
  }

  async registerUser(userData: Partial<User>): Promise<User> {
    // Hash password
    if (userData.password) {
      const salt = await bcrypt.genSalt(10);
      userData.password = await bcrypt.hash(userData.password, salt);
    }

    return this.userRepository.createUser(userData);
  }

  async authenticateUser(email: string, password: string): Promise<string | null> {
    const user = await this.userRepository.findUserByEmail(email);
    
    if (!user) return null;

    const isMatch = await bcrypt.compare(password, user.password);
    
    if (!isMatch) return null;

    // Generate JWT token
    return jwt.sign(
      { id: user.id, email: user.email },
      process.env.JWT_SECRET || '',
      { expiresIn: '1d' }
    );
  }
}
