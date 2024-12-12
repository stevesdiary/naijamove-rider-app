// src/config/database.ts
import { Sequelize } from 'sequelize-typescript';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Create Sequelize instance
const sequelize = new Sequelize({
  dialect: 'postgres', // or mysql, sqlite, etc.
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '5432'),
  username: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  models: [
    __dirname + '/../models/*.model.ts'
  ],
  logging: process.env.NODE_ENV === 'development' ? console.log : false,
  define: {
    underscored: true, // use snake_case for automatically added attributes
    timestamps: true   // enable timestamps
  },
  pool: {
    max: 5,
    min: 0,
    acquire: 30000,
    idle: 10000
  }
});

// Authentication and sync
export const initializeDatabase = async () => {
  try {
    await sequelize.authenticate();
    console.log('Database connection established successfully.');
    
    // Only use force in development
    await sequelize.sync({ 
      force: process.env.NODE_ENV === 'development',
      alter: process.env.NODE_ENV === 'development'
    });
    console.log('Models synchronized with database.');
  } catch (error) {
    console.error('Unable to connect to the database:', error);
    process.exit(1);
  }
};

export default sequelize;
