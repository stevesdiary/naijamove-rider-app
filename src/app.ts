import express, { Application, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';
import morgan from 'morgan';

// Database and Model Imports
// import sequelize, { initializeDatabase } from './config/dbConfig';
import { setupRelationships } from './models';

// Route Imports
import userRoutes from './routes/userRoute';
// import productRoutes from './routes/productRoute';
// import orderRoutes from './routes/order.routes';

// Error Handling
import { 
  NotFoundError, 
  ValidationError, 
  DatabaseConnectionError 
} from './utils/errors';

class App {
  public app: Application;

  constructor() {
    // Initialize environment variables
    dotenv.config();

    // Create Express app
    this.app = express();

    // Initialize middleware
    this.initializeMiddleware();

    // Setup routes
    this.initializeRoutes();

    // Setup error handling
    this.initializeErrorHandling();
  }

  private initializeMiddleware() {
    // Security Middleware
    this.app.use(helmet());

    // CORS Configuration
    this.app.use(cors({
      origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
      methods: ['GET', 'POST', 'PUT', 'DELETE'],
      allowedHeaders: ['Content-Type', 'Authorization']
    }));

    // Request Parsing
    this.app.use(express.json({
      limit: '10mb' // Limit payload size
    }));
    this.app.use(express.urlencoded({ 
      extended: true,
      limit: '10mb'
    }));

    // Compression
    this.app.use(compression());

    // Logging (only in development)
    if (process.env.NODE_ENV === 'development') {
      this.app.use(morgan('dev'));
    }

    // Rate Limiting
    const limiter = rateLimit({
      windowMs: 15 * 60 * 1000, // 15 minutes
      max: 100, // limit each IP to 100 requests per windowMs
      message: 'Too many requests from this IP, please try again later'
    });
    this.app.use(limiter);
  }

  private initializeRoutes() {
    // Health Check Route
    this.app.get('/health', (req: Request, res: Response) => {
      res.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV
      });
    });

    // API Routes
    this.app.use('/api/users', userRoutes);
    // this.app.use('/api/products', productRoutes);
    // this.app.use('/api/orders', orderRoutes);
  }

  private initializeErrorHandling() {
    // 404 Handler
    this.app.use((req: Request, res: Response, next: NextFunction) => {
      throw new NotFoundError('Route not found');
    });

    // Global Error Handler
    // this.app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
    //   console.error(err);

    //   if (err instanceof NotFoundError) {
    //     return res.status(404).json({
    //       status: 'error',
    //       message: err.message
    //     });
    //   }

    //   if (err instanceof ValidationError) {
    //     return res.status(400).json({
    //       status: 'validation_error',
    //       errors: err.errors
    //     });
    //   }

    //   if (err instanceof DatabaseConnectionError) {
    //     return res.status(500).json({
    //       status: 'database_error',
    //       message: 'Database connection failed'
    //     });
    //   }

    //   // Generic server error
    //   res.status(500).json({
    //     status: 'error',
    //     message: 'Internal Server Error',
    //     ...(process.env.NODE_ENV === 'development' && { error: err.message })
    //   });
    // });

    // Unhandled Promise Rejections
    process.on('unhandledRejection', (reason: Error) => {
      console.error('Unhandled Rejection:', reason);
      // Optionally send to error tracking service
    });

    // Uncaught Exceptions
    process.on('uncaughtException', (error: Error) => {
      console.error('Uncaught Exception:', error);
      process.exit(1);
    });
  }

  public async start() {
    const PORT = process.env.PORT ? parseInt(process.env.PORT) : 3000;
    const HOST = process.env.HOST || 'localhost';

    try {
      // Initialize Database Connection
      await initializeDatabase();

      // Setup Model Relationships
      setupRelationships();

      // Start Server
      const server = this.app.listen(PORT, HOST, () => {
        console.log(`
          🚀 Server Running
          ----------------------------
          Environment: ${process.env.NODE_ENV}
          Port: ${PORT}
          Host: ${HOST}
          Timestamp: ${new Date().toISOString()}
        `);
      });

      // Graceful Shutdown
      process.on('SIGTERM', () => {
        console.log('SIGTERM received. Shutting down gracefully');
        server.close(() => {
          console.log('Process terminated');
          process.exit(0);
        });
      });

    } catch (error) {
      console.error('Failed to start server:', error);
      process.exit(1);
    }
  }
}

// Create and start the application
const app = new App();
app.start();

export default app;
