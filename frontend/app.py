from flask import Flask, render_template, request, redirect, session, url_for
from werkzeug.security import generate_password_hash, check_password_hash
from flask_mysqldb import MySQL
from config import Config

app = Flask(__name__)
app.config.from_object(Config)
app.secret_key = "supersecretkey"

mysql = MySQL(app)

# ---------------- HOME PAGE ----------------
@app.route("/")
def home():
    return render_template("home.html")


# ---------------- SIGN UP ----------------
@app.route("/signup", methods=["GET", "POST"])
def signup():
    if request.method == "POST":
        name = request.form["name"]
        email = request.form["email"]
        password = generate_password_hash(request.form["password"])

        cur = mysql.connection.cursor()
        cur.execute("INSERT INTO users(name, email, password) VALUES(%s, %s, %s)",
                    (name, email, password))
        mysql.connection.commit()
        cur.close()

        return redirect("/login")

    return render_template("signup.html")


# ---------------- LOGIN ----------------
@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        email = request.form["email"]
        password = request.form["password"]

        cur = mysql.connection.cursor()
        cur.execute("SELECT * FROM users WHERE email=%s", [email])
        user = cur.fetchone()
        cur.close()

        if user and check_password_hash(user[3], password):
            session["user_id"] = user[0]
            session["user_name"] = user[1]
            return redirect("/dashboard")

        return render_template("login.html", error="Invalid email or password")

    return render_template("login.html")


# ---------------- LOGOUT ----------------
@app.route("/logout")
def logout():
    session.clear()
    return redirect("/")


# ---------------- DASHBOARD (USER BOOKS) ----------------
@app.route("/dashboard")
def dashboard():
    if "user_id" not in session:
        return redirect("/login")

    uid = session["user_id"]

    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM books WHERE user_id=%s", [uid])
    books = cur.fetchall()
    cur.close()

    return render_template("index.html", books=books, username=session["user_name"])


# ---------------- ADD BOOK ----------------
@app.route("/add", methods=["GET", "POST"])
def add():
    if "user_id" not in session:
        return redirect("/login")

    if request.method == "POST":
        title = request.form["title"]
        author = request.form["author"]

        cur = mysql.connection.cursor()
        cur.execute("INSERT INTO books(title, author, user_id) VALUES(%s, %s, %s)",
                    (title, author, session["user_id"]))
        mysql.connection.commit()
        cur.close()

        return redirect("/dashboard")

    return render_template("add.html")


# ---------------- EDIT BOOK ----------------
@app.route("/edit/<id>", methods=["GET", "POST"])
def edit(id):
    if "user_id" not in session:
        return redirect("/login")

    uid = session["user_id"]

    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM books WHERE id=%s AND user_id=%s", (id, uid))
    book = cur.fetchone()

    if not book:
        return "Unauthorized"

    if request.method == "POST":
        title = request.form["title"]
        author = request.form["author"]

        cur.execute("UPDATE books SET title=%s, author=%s WHERE id=%s AND user_id=%s",
                    (title, author, id, uid))
        mysql.connection.commit()
        cur.close()

        return redirect("/dashboard")

    cur.close()
    return render_template("edit.html", book=book)


# ---------------- DELETE BOOK ----------------
@app.route("/delete/<id>")
def delete(id):
    if "user_id" not in session:
        return redirect("/login")

    uid = session["user_id"]

    cur = mysql.connection.cursor()
    cur.execute("DELETE FROM books WHERE id=%s AND user_id=%s", (id, uid))
    mysql.connection.commit()
    cur.close()

    return redirect("/dashboard")


# ---------------- RUN APP ----------------
if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
