"""Project settings"""
import os


# Flask
DEBUG = os.environ.get("DEBUG") == "True"
PORT = os.environ.get("PORT") or 80
