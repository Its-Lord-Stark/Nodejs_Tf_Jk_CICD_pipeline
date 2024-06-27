const express = require("express");
const app = express();
const PORT = 8100;

app.set("view engine", "ejs");

app.set("views", __dirname + "/views");

app.get("/", (req, res) => {
    res.render("home.ejs"); 
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
