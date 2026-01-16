import dotenv from "dotenv";
dotenv.config();
import express from 'express';
import mongoose from 'mongoose';
import http from 'http';
import cors from 'cors';
import { userRouter } from './routes/user.route.js';
import { storyRouter } from './routes/story.route.js'; 
import { videoRouter} from './routes/video.route.js';
import { quizRouter} from './routes/quiz.route.js';
import { aiRouter } from './routes/ai.route.js'; 
import { reviewStoryRouter } from './routes/reviewStory.route.js';
import { storyLikeRouter } from './routes/storyLike.route.js';
import { templateRouter } from './routes/template.route.js';
import uploadRouter  from './routes/upload.routes.js';
import { taskRouter } from './routes/task.route.js';
import { playlistRouter } from "./routes/playlist.route.js";    
import { gameRouter } from "./routes/game.route.js";   
import { historyRouter} from "./routes/videoHistory.route.js"; 
import {dailywatchRouter} from './routes/dailyWatch.route.js'
import { notificationRouter } from "./routes/notification.routes.js";
import storyTemplateRouter from "./routes/storyTemplate.routes.js";
import { badgeRouter } from "./routes/badge.routes.js";
import { drawingRouter } from "./routes/drawing.route.js";
import { drawingCopyAiRouter } from "./routes/drawingCopyAi.route.js";
import { drawingTimeRouter } from "./routes/drawingTime.route.js";
import { kidsQuoteRouter } from "./routes/kidsQuote.routes.js";
import { colorByNumberProgressRouter } from "./routes/colorByNumberProgress.route.js";
import { storyWritingTimeRouter } from "./routes/storyWritingTime.route.js";

const app = express()
const server = http.createServer(app);
app.use(cors());


// إعدادات CORS
const corsOptions = {
    origin:
    //"*",
     [
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
app.use('/api',videoRouter);
app.use('/api',quizRouter);
app.use('/api/ai', aiRouter);
app.use('/api', reviewStoryRouter);
app.use('/api', storyLikeRouter );
app.use('/api', templateRouter );
app.use("/api/upload", uploadRouter);
app.use('/api', taskRouter );
app.use('/api', playlistRouter);
app.use('/api', historyRouter);
app.use('/api', dailywatchRouter);
app.use("/api", notificationRouter);
app.use("/api/stories", storyTemplateRouter);
app.use("/api", badgeRouter);
app.use("/api", drawingRouter);
app.use("/api", drawingCopyAiRouter);
app.use("/api", drawingTimeRouter);
app.use("/api", kidsQuoteRouter);
app.use("/api", storyWritingTimeRouter);
app.use("/", colorByNumberProgressRouter);
app.get('/', (req,res) => {
    res.send("hello from node api server using express");
});


// connect to mongoDB database using mongoose
mongoose.connect("mongodb+srv://fatima2004nasser_db_user:ddLRmTvoPt6mmpRJ@cluster.ginozpp.mongodb.net/Node-API?retryWrites=true&w=majority&appName=Cluster")
.then(() => {

    // first connect to the DB then start the server
       console.log("connected to DB");
       app.listen(3000, "0.0.0.0",() => {
           console.log('server is running on port 3000');
        });
})

.catch((err) => {
    console.error("Error connecting to DB:", err);
} );
