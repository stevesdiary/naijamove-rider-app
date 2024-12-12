import { DataTypes } from 'sequelize';
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


@Table({
  tableName: 'orders',
  timestamps: true
})
export class Order extends Model {
  @Column({
		type: DataTypes.UUID,
		defaultValue: DataTypes.UUIDV4,
		primaryKey: true
	})
	id!: string;

  @ForeignKey(() => User)
	@Column({
		type: DataTypes.UUID,
		allowNull: false
	})
	consumerId!: string;

  @BelongsTo(() => User)
	consumer!: User;

  @Column({
		type: DataTypes.ENUM(
			'pending',
			'processing',
			'shipped',
			'delivered',
			'cancelled'
		),
		defaultValue: 'pending'
	})
	status!: string;

  @Column({
		type: DataTypes.DECIMAL(10, 2),
		allowNull: false
	})
	totalAmount!: number;

  @Column({
		type: DataTypes.STRING
	})
	paymentMethod!: string;

  @HasMany(() => OrderItem)
	orderItems!: OrderItem[];
}

// Order Item Model
@Table({
  tableName: 'order_items',
  timestamps: true
})
export class OrderItem extends Model {
  @ForeignKey(() => Order)
	@Column({
		type: DataTypes.UUID,
		allowNull: false
	})
	orderId!: string;

  @BelongsTo(() => Order)
	order!: Order;

  @ForeignKey(() => Product)
	@Column({
		type: DataTypes.UUID,
		allowNull: false
	})
	productId!: string;

  @BelongsTo(() => Product)
  product!: Product;

  @Column({
		type: DataTypes.INTEGER,
		allowNull: false
	})
	quantity!: number;

  @Column({
		type: DataTypes.DECIMAL(10, 2),
		allowNull: false
	})
	price!: number;
}
