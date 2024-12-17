import { Sequelize } from 'sequelize-typescript';
import config from './dbConfig';

const sequelize = new Sequelize({
    ...config.getDatabaseConfig(),
    dialect: 'mysql',
    models: [__dirname + '/models'],
})

export default sequelize;

