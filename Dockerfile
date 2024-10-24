# Use the official Haskell image
FROM haskell:8.10

# Set the working directory
WORKDIR /usr/src/app

# Copy the stack configuration and package files
COPY stack.yaml ./
COPY package.yaml ./

# Install Stack
RUN stack setup

# Copy the rest of the project files
COPY . .

# Build the Haskell project
RUN stack build --fast -v

# Expose the port the app runs on
EXPOSE 3000

# Run the application
CMD ["stack", "exec", "haskell-option-pricing-exe"]

