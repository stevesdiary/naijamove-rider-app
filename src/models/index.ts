// src/models/index.ts
import { User } from './User';
import { FarmerProfile } from './Farmer';
import { Product } from './Product';
import { Order } from './Order';
import { OrderItem } from './Order';
import { Review } from './Review';
import { Message } from './Message';

// Define model relationships
export const setupRelationships = () => {
  // User to FarmerProfile (One-to-One)
  User.hasOne(FarmerProfile, {
    foreignKey: 'userId',
    as: 'farmerProfile'
  });
  FarmerProfile.belongsTo(User, {
    foreignKey: 'userId',
    as: 'user'
  });

  // FarmerProfile to Products (One-to-Many)
  FarmerProfile.hasMany(Product, {
    foreignKey: 'farmerId',
    as: 'products'
  });
  Product.belongsTo(FarmerProfile, {
    foreignKey: 'farmerId',
    as: 'farmer'
  });

  // User to Orders (One-to-Many)
  User.hasMany(Order, {
    foreignKey: 'consumerId',
    as: 'orders'
  });
  Order.belongsTo(User, {
    foreignKey: 'consumerId',
    as: 'consumer'
  });

  // Product to OrderItems (One-to-Many)
  Product.hasMany(OrderItem, {
    foreignKey: 'productId',
    as: 'orderItems'
  });
  OrderItem.belongsTo(Product, {
    foreignKey: 'productId',
    as: 'product'
  });

  // Order to OrderItems (One-to-Many)
  Order.hasMany(OrderItem, {
    foreignKey: 'orderId',
    as: 'orderItems'
  });
  OrderItem.belongsTo(Order, {
    foreignKey: 'orderId',
    as: 'order'
  });

  // Product to Reviews (One-to-Many)
  Product.hasMany(Review, {
    foreignKey: 'productId',
    as: 'reviews'
  });
  Review.belongsTo(Product, {
    foreignKey: 'productId',
    as: 'product'
  });
};
