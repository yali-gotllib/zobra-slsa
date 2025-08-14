# Use Python 3.9 slim image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy source code
COPY zobra/ zobra/
COPY pyproject.toml .
COPY README.md .

# Install the package
RUN pip install --no-cache-dir -e .

# Set the entrypoint
ENTRYPOINT ["python", "-m", "zobra.cli"]
CMD ["--help"]
