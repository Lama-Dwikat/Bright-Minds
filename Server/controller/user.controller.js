import "./services/user.service.js";

export const userController = (app) => {
    const { signUp, signIn, getAllUsers, getUserById, getUserByUsername } = userService();

    app.post('/signup', async (req, res) => {
        try {
            const user = await signUp(req.body);
            res.status(201).json(user);
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    });

    app.post('/signin', async (req, res) => {
        try {
            const user = await signIn(req.body.username, req.body.password);
            res.status(200).json(user);
        } catch (error) {
            res.status(401).json({ error: error.message });
        }
    });

    app.get('/users', async (req, res) => {
        try {
            const users = await getAllUsers();
            res.status(200).json(users);
        } catch (error) {
            res.status(500).json({ error: error.message });
    }});
    
    app.get('/users/:id', async (req, res) => {
        try {
            const user = await getUserById(req.params.id);
            res.status(200).json(user);
        } catch (error) {
            res.status(404).json({ error: error.message });
        }
    });                                                   
}