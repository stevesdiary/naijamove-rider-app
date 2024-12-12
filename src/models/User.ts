import { 
  Model,
  Table, 
  Column, 
  ForeignKey, 
  BelongsTo, 
  HasMany 
} from 'sequelize-typescript';
import { DataTypes } from 'sequelize';

// User Model (Base for both Farmers and Consumers)
@Table({
  tableName: 'users',
  timestamps: true
})
export class User extends Model {
  @Column({
		type: DataTypes.UUID,
		defaultValue: DataTypes.UUIDV4,
		primaryKey: true
	})
	id!: string;

  @Column({
		type: DataTypes.STRING,
		allowNull: false
	})
	email!: string;

  @Column({
		type: DataTypes.STRING,
		allowNull: false
	})
	password!: string;

  @Column({
		type: DataTypes.ENUM('farmer', 'consumer'),
		allowNull: false
	})
	userType!: string;

  @Column({
		type: DataTypes.STRING
	})
	firstName!: string;

  @Column({
		type: DataTypes.STRING
	})
	lastName!: string;

  @Column({
		type: DataTypes.STRING
	})
	phoneNumber!: string;

  @Column({
		type: DataTypes.BOOLEAN,
		defaultValue: false
	})
	isVerified!: boolean;
}
