from flask import Flask, render_template
import os

application = Flask(__name__)


@application.route("/")
def root():
    return render_template("index.html")

@application.route("/help")
def helppage():
    return render_template("help.html")

@application.route("/info")
def infopage():
    Endpoint = os.getenv('DB_ENDPOINT', "my-database-1.cluster-cnpexample.us-east-1.rds.amazonaws.com") # Read Environment Variable : default
    DBClusterIdentifier = os.getenv('DBClusterIdentifier',  "my-database-1")   # Read Environment Variable : default
    INFO_MESSAGE = "Info: <b>" + Endpoint + " " + DBClusterIdentifier + "</b> :)"
    return INFO_MESSAGE

if __name__ == "__main__":
    application.run(host="0.0.0.0", port=8080)

