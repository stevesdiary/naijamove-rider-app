import { 
  Model, 
  Table, 
  Column, 
  ForeignKey, 
  BelongsTo, 
  HasMany 
} from 'sequelize-typescript';
import { User } from './User';
import { DataTypes } from 'sequelize';
import { Product } from './Product';

@Table({
  tableName: 'farmer_profiles',
  timestamps: true
})
export class FarmerProfile extends Model {
  @ForeignKey(() => User)
	@Column({
		type: DataTypes.UUID,
		allowNull: false
	})
	userId!: string;

  @BelongsTo(() => User)
	user: User = new User;

  @Column({
		type: DataTypes.STRING
	})
	farmName!: string;

  @Column({
		type: DataTypes.TEXT
	})
	farmDescription!: string;

  @Column({
		type: DataTypes.STRING
	})
	location!: string;

  @HasMany(() => Product)
	products!: Product[];
}