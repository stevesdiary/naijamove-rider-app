const config = {
  env: process.env.NODE_ENV || 'development',
  debug: process.env.APP_DEBUG === 'true',
  port: parseInt(process.env.PORT || '3000'),
  getDatabaseConfig: () => ({
    database: process.env.DB_NAME,
    host: process.env.DB_HOST,
    username: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    port: parseInt(process.env.DB_PORT || '3306')
  }),
};

export default config;
