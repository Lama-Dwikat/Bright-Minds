import dotenv from "dotenv";
dotenv.config();
import express from 'express';
import mongoose from 'mongoose';
import http from 'http';
import cors from 'cors';
import { userRouter } from './routes/user.route.js';
import { storyRouter } from './routes/story.route.js'; 
import { videoRouter} from './routes/video.route.js';
import { quizeRouter} from './routes/quize.route.js';



const app = express()
const server = http.createServer(app);
app.use(cors());


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
// app.use(express.json());
// Increase JSON body size to 5MB (or more if needed)
app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ limit: '5mb', extended: true }));
//app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api', userRouter);
app.use('/api', storyRouter);
app.use('/api/',videoRouter);
app.use('/api/',quizeRouter);




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
