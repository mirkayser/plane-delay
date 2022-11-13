"""Project settings"""
import os


# Flask
DEBUG = os.environ.get("DEBUG") == "True"
