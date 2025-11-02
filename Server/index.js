import dotenv from "dotenv";
dotenv.config();
import express from 'express';
import mongoose from 'mongoose';
import http from 'http';
import cors from 'cors';
import { userRouter } from './routes/user.route.js';

const app = express()
const server = http.createServer(app);



// إعدادات CORS
const corsOptions = {
    origin: [
        "http://localhost:3000",
        "http://localhost:3001"
    ],
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE"],
};

app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api', userRouter);



app.get('/', (req,res) => {
    res.send("hello from node api server using express");
});


// connect to mongoDB database using mongoose
mongoose.connect("mongodb+srv://fatima2004nasser_db_user:ddLRmTvoPt6mmpRJ@cluster.ginozpp.mongodb.net/Node-API?retryWrites=true&w=majority&appName=Cluster")
.then(() => {

    // first connect to the DB then start the server
       console.log("connected to DB");
       app.listen(3000,() => {
           console.log('server is running on port 3000');
        });
})

.catch((err) => {
    console.error("Error connecting to DB:", err);
} );
