import { 
  Model, 
  Table, 
  Column,
	DataType,
  ForeignKey, 
  BelongsTo, 
  HasMany, 
	PrimaryKey
} from 'sequelize-typescript';
// import { User } from './User';
import { Optional, UUIDV4 } from 'sequelize';
import { Product } from './Product';
import { Col } from 'sequelize/types/utils';
interface FarmerAttributes {
	id: string,
	name: string
}

interface FarmerCreationAttributes extends Optional<FarmerAttributes, 'id'> {}
@Table({
	timestamps: true,
	tableName: 'farmers',
	modelName: 'Farmer'
})
export default class Farmer extends Model<
	FarmerAttributes,
	FarmerCreationAttributes
	>{
		@Column({
			primaryKey: true,
			type: DataType.UUID,
			defaultValue: UUIDV4
		})
		declare id: string;

		@Column({
			type: DataType.STRING,
		})
		declare name: string;

		@Column({
			type: DataType.STRING
		})
		declare farmName: string;

		@Column({
			type: DataType.STRING
		})
		declare farmLocation: string;

		@Column({
			type: DataType.BIGINT
		})
		declare phone: BigInt;

		@Column({
			type: DataType.ENUM('customer', 'farmer', 'admin')
		})
		declare type: string
		
	}