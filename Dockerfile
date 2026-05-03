# Use the official Python 3.8 slim image as the base image
FROM python:3.8-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the requirements.txt file first (this leverages Docker's cache for faster builds)
COPY requirements.txt .

# Install the dependencies specified in the requirements.txt file
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code and test files into the container
COPY app.py .
COPY test_app.py .

# Create a non-root user to improve security (this is a basic improvement)
RUN useradd -m appuser

# Expose the port the app will run on (Flask runs by default on port 5000)
EXPOSE 5000

# Run the application (currently as root, which is a security vulnerability)
CMD ["python", "app.py"]