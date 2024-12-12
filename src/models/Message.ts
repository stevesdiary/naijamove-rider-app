import { DataTypes } from 'sequelize';
import { 
  Model, 
  Table, 
  Column, 
  ForeignKey, 
  BelongsTo, 
  HasMany 
} from 'sequelize-typescript';
import { User } from './User';


@Table({
  tableName: 'messages',
  timestamps: true
})
export class Message extends Model {
  @ForeignKey(() => User)
	@Column({
		type: DataTypes.UUID,
		allowNull: false
	})
	senderId!: string;

  @ForeignKey(() => User)
	@Column({
		type: DataTypes.UUID,
		allowNull: false
	})
	receiverId!: string;

  @Column({
		type: DataTypes.TEXT,
		allowNull: false
	})
	content!: string;

  @Column({
		type: DataTypes.BOOLEAN,
		defaultValue: false
	})
	isRead!: boolean;
}