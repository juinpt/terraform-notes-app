"""
Flask Notes App
===============

This application provides a simple web interface for:

- User registration and login (with hashed passwords in PostgreSQL via Amazon RDS)
- Note creation and full-text search using Amazon OpenSearch
- Session-based authentication with Flask
- HTML rendering via Jinja2 templates

Environment Variables Required:
-------------------------------
- POSTGRES_HOST:     RDS PostgreSQL host
- POSTGRES_PORT:     PostgreSQL port (default: 5432)
- POSTGRES_DB:       Database name
- POSTGRES_USER:     Username
- POSTGRES_PASSWORD: Password
- OPENSEARCH_HOST:   OpenSearch domain endpoint (without https://)
- AWS_REGION:        AWS region
- FLASK_SECRET_KEY:  Secret key for Flask session handling

"""


from flask import Flask, request, jsonify, render_template, redirect, url_for, session
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager, jwt_required, create_access_token, get_jwt_identity
from opensearchpy import OpenSearch, RequestsHttpConnection
from uuid import uuid4
import psycopg2
import boto3
from requests_aws4auth import AWS4Auth
import os

app = Flask(__name__)
app.secret_key = os.environ["FLASK_SECRET_KEY"]

bcrypt = Bcrypt(app)
jwt = JWTManager(app)

# Amazon OpenSearch setup
region = os.environ["AWS_REGION"]
credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, region, "es", session_token=credentials.token)

es = OpenSearch(
    hosts=[{"host": os.environ["OPENSEARCH_HOST"], "port": 443}],
    http_auth=awsauth,
    use_ssl=True,
    verify_certs=True,
    connection_class=RequestsHttpConnection
)

INDEX = "notes"
if not es.indices.exists(index=INDEX):
    es.indices.create(index=INDEX)

# PostgreSQL connection
conn = psycopg2.connect(
    dbname=os.environ["POSTGRES_DB"],
    user=os.environ["POSTGRES_USER"],
    password=os.environ["POSTGRES_PASSWORD"],
    host=os.environ["POSTGRES_HOST"],
    port=os.environ["POSTGRES_PORT"]
)
cursor = conn.cursor()
cursor.execute("""
    CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
    );
""")
conn.commit()

@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        username = request.form["username"]
        password = bcrypt.generate_password_hash(request.form["password"]).decode('utf-8')
        try:
            cursor.execute("INSERT INTO users (username, password) VALUES (%s, %s)", (username, password))
            conn.commit()
            return redirect(url_for("login"))
        except Exception as e:
            return f"Error: {str(e)}"
    return render_template("register.html")

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form["username"]
        password = request.form["password"]
        cursor.execute("SELECT password FROM users WHERE username = %s", (username, ))
        user = cursor.fetchone()
        if user and bcrypt.check_password_hash(user[0], password):
            session["user"] = username
            return redirect(url_for("notes"))
        else:
            return "Invalid credentials"
    return render_template("login.html")

@app.route("/logout")
def logout():
    session.pop("user", None)
    return redirect(url_for("login"))

@app.route("/notes", methods=["GET"])
def notes():
    if "user" not in session:
        return redirect(url_for("login"))
    query = request.args.get("q", "")
    if query:
        result = es.search(index=INDEX, body={"query": {"multi_match": {"query": query,"fields": ["title", "content"]}}})
        hits = [hit["_source"] for hit in result["hits"]["hits"]]
    else:
        hits = []
    return render_template("notes.html", notes=hits)

@app.route("/notes/new", methods=["GET", "POST"])
def new_note():
    if "user" not in session:
        return redirect(url_for("login"))
    if request.method == "POST":
        title = request.form["title"]
        content = request.form["content"]
        note_id = str(uuid4())
        note = {
            "id": note_id,
            "title": title,
            "content": content
        }
        es.index(index=INDEX, id=note_id, body=note)
        return redirect(url_for("notes"))
    return render_template("new_note.html")

@app.route("/")
def home():
    if "user" in session:
        return redirect(url_for("notes"))
    return redirect(url_for("login"))

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
