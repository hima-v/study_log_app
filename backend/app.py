from flask import Flask, jsonify, request
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
app.config[
    "SQLALCHEMY_DATABASE_URI"
] = "sqlite:///study_logs.db"  # SQLite database file
db = SQLAlchemy(app)


class StudyLog(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user = db.Column(db.String(50), nullable=False)
    subject = db.Column(db.String(50), nullable=False)
    chapter = db.Column(db.String(50), nullable=False)
    task_done = db.Column(db.String(255), nullable=False)
    percent_completed = db.Column(db.Integer, nullable=False)


with app.app_context():
    db.create_all()


@app.route("/study_logs", methods=["POST"])
def add_study_log():
    data = request.get_json()

    new_log = StudyLog(
        user=data["user"],
        subject=data["subject"],
        chapter=data["chapter"],
        task_done=data["task_done"],
        percent_completed=data["percent_completed"],
    )

    db.session.add(new_log)
    db.session.commit()

    return jsonify({"message": "Study log added successfully"}), 201


@app.route("/study_logs", methods=["GET"])
def get_study_logs():
    study_logs = StudyLog.query.all()
    logs = [
        {
            "user": log.user,
            "subject": log.subject,
            "chapter": log.chapter,
            "task_done": log.task_done,
            "percent_completed": log.percent_completed,
        }
        for log in study_logs
    ]

    return jsonify({"study_logs": logs})


if __name__ == "__main__":
    app.run(debug=True)
