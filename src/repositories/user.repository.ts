// src/repositories/user.repository.ts
import { User, Farmer } from '../models';
// import { FarmerProfile } from '../models/farmer-profile.model';

export class UserRepository {
  async createUser(userData: Partial<User>): Promise<User> {
    return User.create(userData);
  }

  async findUserByEmail(email: string): Promise<User | null> {
    return User.findOne({ 
      where: { email },
      include: [
        {
          model: Farmer,
          as: 'farmer'
        }
      ]
    });
  }

  async updateUser(id: string, updateData: Partial<User>): Promise<[number, User[]]> {
    return User.update(updateData, {
      where: { id },
      returning: true
    });
  }
}
