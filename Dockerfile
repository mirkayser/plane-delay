FROM python:3.10-slim

# Install system dependencies
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        python3-dev

WORKDIR /app

# Add application requirements
COPY requirements.txt .

# Install python dependencies
RUN pip install --upgrade pip setuptools wheel && \
    pip install -r requirements.txt

# Add application source code
COPY . .

# Run WSGI server
EXPOSE 80
CMD python app.py
