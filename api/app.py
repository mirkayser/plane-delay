"""Api serving model predicting if plane will be delayed."""

import pickle5
from flask import Flask, request
from flask_restful import abort, Api, Resource
import numpy as np

import settings


# init Flask Api
app = Flask(__name__)
api = Api(app)

# load pickled model
with open("./pickle_model.pkl", "rb") as f:
    clf = pickle5.load(f)


# create resources
class ClassifierApi(Resource):
    """Resource to predict if plane will be delayed."""

    def get(self) -> dict:
        params = request.get_json()

        x = np.array(params.get("x")).reshape(1, -1)
        prediction = clf.predict(x)
        probability = clf.predict_proba(x)

        return {"prediction": prediction.tolist(), "probability": probability.tolist()}


# register paths
api.add_resource(ClassifierApi, "/predict")


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=settings.PORT,
        debug=settings.DEBUG,
    )
