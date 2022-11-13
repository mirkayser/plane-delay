import pickle5
from flask import Flask, request
from flask_restful import abort, Api, Resource
import numpy as np

import settings


app = Flask(__name__)
api = Api(app)

with open("./pickle_model.pkl", "rb") as f:
    clf = pickle5.load(f)


class ClassifierApi(Resource):
    def get(self):
        params = request.get_json()

        x = np.array(params.get("x")).reshape(1, -1)
        prediction = clf.predict(x)
        probability = clf.predict_proba(x)

        return {"prediction": prediction.tolist(), "probability": probability.tolist()}


api.add_resource(ClassifierApi, "/")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=settings.DEBUG)
