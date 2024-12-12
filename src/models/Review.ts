import { 
  Model, 
  Table, 
  Column, 
  ForeignKey, 
  BelongsTo, 
  HasMany 
} from 'sequelize-typescript';
import { Product } from './Product';
import { User } from './User';
import { DataTypes } from 'sequelize';

@Table({
  tableName: 'reviews',
  timestamps: true
})
export class Review extends Model {
  @ForeignKey(() => Product)
	@Column({
		type: DataTypes.UUID,
		allowNull: false
	})
	productId!: string;

  @BelongsTo(() => Product)
  product!: Product;

  @ForeignKey(() => User)
	@Column({
		type: DataTypes.UUID,
		allowNull: false
	})
	consumerId!: string;

  @BelongsTo(() => User)
  consumer!: User;

  @Column({
		type: DataTypes.INTEGER,
		validate: {
			min: 1,
			max: 5
		}
	})
	rating!: number;

  @Column({
		type: DataTypes.TEXT
	})
	comment!: string;
}
