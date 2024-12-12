import { 
  Model,
  Table, 
  Column, 
  ForeignKey, 
  BelongsTo, 
  HasMany 
} from 'sequelize-typescript';
import { FarmerProfile } from './Farmer';
import { DataTypes } from 'sequelize';
import { Review } from './Review';

@Table({
  tableName: 'products',
  timestamps: true
})
export class Product extends Model {
  @Column({
		type: DataTypes.UUID,
		defaultValue: DataTypes.UUIDV4,
		primaryKey: true
	})
	id!: string;

  @ForeignKey(() => FarmerProfile)
	@Column({
		type: DataTypes.UUID,
		allowNull: false
	})
	farmerId!: string;

  @BelongsTo(() => FarmerProfile)
  farmer!: FarmerProfile;

  @Column({
		type: DataTypes.STRING,
		allowNull: false
	})
	name!: string;

  @Column({
		type: DataTypes.TEXT
	})
	description!: string;

  @Column({
		type: DataTypes.DECIMAL(10, 2),
		allowNull: false
	})
	price!: number;

  @Column({
		type: DataTypes.INTEGER
	})
	stockQuantity!: number;

  @Column({
		type: DataTypes.STRING
	})
	category!: string;

  @Column({
		type: DataTypes.TEXT
	})
	nutritionalInfo!: string;

  @Column({
		type: DataTypes.STRING
	})
	imageUrl!: string;

  @HasMany(() => Review)
	reviews!: Review[];
}