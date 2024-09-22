import express from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import dotenv from 'dotenv';
import cors from "cors";
import newVideos from './mongodb.js';
import { initializeApp } from 'firebase/app';
import { getStorage, ref, uploadBytes, getDownloadURL } from 'firebase/storage';

// Load environment variables
dotenv.config();

// Firebase configuration
const firebaseConfig = {
    apiKey: process.env.FIREBASE_API_KEY,
    authDomain: process.env.FIREBASE_AUTH_DOMAIN,
    projectId: process.env.FIREBASE_PROJECT_ID,
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
    messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
    appId: process.env.FIREBASE_APP_ID,
};
// Initialize Firebase
const firebaseApp = initializeApp(firebaseConfig);
const storage = getStorage(firebaseApp);

const app = express();
const PORT = 3000;

// Serve static files from "public" directory
app.use(express.static(path.join(path.resolve(), 'public')));
app.use(express.json());
app.use(cors());
// Set up multer for file uploads
const multerStorage = multer.diskStorage({
    destination: function (req, file, cb) {
        const uploadPath = path.join(path.resolve(), 'public', 'uploads');
        if (!fs.existsSync(uploadPath)) {
            fs.mkdirSync(uploadPath, { recursive: true });
        }
        cb(null, uploadPath);
    },
    filename: function (req, file, cb) {
        cb(null, `${Date.now()}-${file.originalname}`);
    }
});

const upload = multer({ storage: multerStorage });

// Serve static files from "public/uploads" directory (for uploaded videos)
//app.use('/uploads', express.static(path.join(path.resolve(), 'public', 'uploads')));

// Handle video upload
app.post('/upload-video', upload.single('videoFile'), async (req, res) => {
    try {
        const length = await newVideos.find();
        let hlo= length.length;

        const { title, description } = req.body;
        if (!title || !description || !req.file) {
            return res.status(400).json({ error: 'All fields are required' });
        }

        // Upload file to Firebase Storage
        const filePath = req.file.path; // Local file path
        const storageRef = ref(storage, `uploads/${req.file.filename}`); // Reference in Firebase Storage

        // Read file and upload
        const fileData = fs.readFileSync(filePath);
        await uploadBytes(storageRef, fileData);

        // Get the download URL
        const videoPath = await getDownloadURL(storageRef);

        // Save video info to MongoDB
        await newVideos.insertMany({number:(hlo+1) , title, description, videoPath });

        // Remove the file from local storage after successful upload
        fs.unlinkSync(filePath);

        res.json({ message: 'Video uploaded successfully!'});
    } catch (error) {
        console.error('Error uploading video:', error);
        res.status(500).json({ error: 'Failed to upload video' });
    }
});
app.get('/all-video', async (req, res) => {
    const allvideo = await newVideos.find();
    res.json(allvideo);
})
// Start the server
app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
