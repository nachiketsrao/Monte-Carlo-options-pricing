# Use an official Haskell image as a base
FROM haskell:latest

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy the current directory contents into the container at /usr/src/app
COPY . .

# Install any additional system-level dependencies (optional)
# RUN apt-get update && apt-get install -y <additional-package>

# Build the Haskell project using Stack
RUN stack setup
RUN stack build

# Open a port (if your Haskell application is a web server)
# EXPOSE 8080

# Define the command to run your app
CMD ["stack", "exec", "my-project-exe"]
